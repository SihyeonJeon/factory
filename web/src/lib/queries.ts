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
  const { data: event, error } = await supabase
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
    .single();

  if (error || !event) return null;

  // Count confirmed guests
  const { count } = await supabase
    .from("guest_states")
    .select("id", { count: "exact", head: true })
    .eq("event_id", id);

  const host = event.profiles as unknown as {
    display_name: string;
    avatar_url: string | null;
  } | null;

  return {
    id: event.id,
    title: event.title,
    datetime: event.datetime,
    location: event.location,
    description: event.description,
    mood: event.mood,
    coverImage: event.cover_image_url,
    hostName: host?.display_name ?? "호스트",
    hostAvatar: host?.avatar_url ?? null,
    guestCount: count ?? 0,
    hasFee: event.has_fee,
  };
}
