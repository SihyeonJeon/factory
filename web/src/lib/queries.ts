import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database.types";
import type { EventDetail, EventMood } from "./types";

/** Lightweight event summary for list views (no signed URLs). */
export interface EventSummary {
  id: string;
  title: string;
  datetime: string;
  location: string;
  mood: EventMood;
  hostId: string;
  hostName: string;
  guestCount: number;
  role: "host" | "guest";
}

/**
 * Fetch all events where the user is host or guest.
 * Returns events sorted by datetime descending (most recent first).
 */
export async function getMyEvents(
  supabase: SupabaseClient<Database>,
  userId: string,
): Promise<EventSummary[]> {
  // Two parallel queries: hosted events + attending events
  const [hostedResult, guestResult] = await Promise.all([
    supabase
      .from("events")
      .select(`
        id, title, datetime, location, mood, host_id,
        profiles!events_host_id_fkey ( display_name ),
        guest_states ( id )
      `)
      .eq("host_id", userId)
      .order("datetime", { ascending: false })
      .limit(50),
    supabase
      .from("guest_states")
      .select(`
        event_id,
        events!inner (
          id, title, datetime, location, mood, host_id,
          profiles!events_host_id_fkey ( display_name ),
          guest_states ( id )
        )
      `)
      .eq("user_id", userId)
      .limit(50),
  ]);

  if (hostedResult.error) {
    console.error("[getMyEvents] hosted query error:", hostedResult.error.message);
  }
  if (guestResult.error) {
    console.error("[getMyEvents] guest query error:", guestResult.error.message);
  }

  const eventMap = new Map<string, EventSummary>();

  // Process hosted events
  for (const row of hostedResult.data ?? []) {
    const host = row.profiles as unknown as { display_name: string } | null;
    const guests = row.guest_states as unknown as { id: string }[] | null;
    eventMap.set(row.id, {
      id: row.id,
      title: row.title,
      datetime: row.datetime,
      location: row.location,
      mood: row.mood,
      hostId: row.host_id,
      hostName: host?.display_name ?? "호스트",
      guestCount: guests?.length ?? 0,
      role: "host",
    });
  }

  // Process guest events (skip if already in map as host)
  for (const row of guestResult.data ?? []) {
    const event = row.events as unknown as {
      id: string;
      title: string;
      datetime: string;
      location: string;
      mood: EventMood;
      host_id: string;
      profiles: { display_name: string } | null;
      guest_states: { id: string }[] | null;
    };
    if (!event || eventMap.has(event.id)) continue;
    eventMap.set(event.id, {
      id: event.id,
      title: event.title,
      datetime: event.datetime,
      location: event.location,
      mood: event.mood,
      hostId: event.host_id,
      hostName: event.profiles?.display_name ?? "호스트",
      guestCount: event.guest_states?.length ?? 0,
      role: "guest",
    });
  }

  // Sort by datetime descending
  return Array.from(eventMap.values()).sort(
    (a, b) => new Date(b.datetime).getTime() - new Date(a.datetime).getTime(),
  );
}

/**
 * Fetch a single event by ID and map it to the EventDetail shape
 * used by frontend components.
 */
export async function getEventById(
  supabase: SupabaseClient<Database>,
  id: string,
): Promise<EventDetail | null> {
  // Parallel queries: fetch event + count guests simultaneously
  const [eventResult, countResult] = await Promise.all([
    supabase
      .from("events")
      .select(
        `
        id,
        title,
        datetime,
        location,
        description,
        mood,
        cover_image_url,
        has_fee,
        host_id,
        profiles!events_host_id_fkey ( display_name, avatar_url )
      `,
      )
      .eq("id", id)
      .single(),
    supabase
      .from("guest_states")
      .select("id", { count: "exact", head: true })
      .eq("event_id", id),
  ]);

  const { data: event, error } = eventResult;
  if (error || !event) return null;

  const { count } = countResult;

  const host = event.profiles as unknown as {
    display_name: string;
    avatar_url: string | null;
  } | null;

  // Resolve cover image: storage path → signed URL (1-hour TTL)
  let coverImage: string | null = null;
  if (event.cover_image_url) {
    const raw = event.cover_image_url;
    if (raw.startsWith("http")) {
      coverImage = raw;
    } else {
      const { data: urlData } = await supabase.storage
        .from("event-media")
        .createSignedUrl(raw, 60 * 60);
      coverImage = urlData?.signedUrl ?? null;
    }
  }

  return {
    id: event.id,
    title: event.title,
    datetime: event.datetime,
    location: event.location,
    description: event.description,
    mood: event.mood,
    coverImage,
    hostId: event.host_id,
    hostName: host?.display_name ?? "호스트",
    hostAvatar: host?.avatar_url ?? null,
    guestCount: count ?? 0,
    hasFee: event.has_fee,
  };
}
