import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database.types";
import type { EventDetail } from "./types";

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
    hostName: host?.display_name ?? "호스트",
    hostAvatar: host?.avatar_url ?? null,
    guestCount: count ?? 0,
    hasFee: event.has_fee,
  };
}
