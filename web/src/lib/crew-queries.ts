import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database.types";
import type { Crew, CrewMember, CrewFeedEvent, CrewRole, EventMood } from "./types";

/**
 * Fetch all crews where the user is a member.
 */
export async function getMyCrews(
  supabase: SupabaseClient<Database>,
  userId: string,
): Promise<Crew[]> {
  const { data, error } = await supabase
    .from("crew_members")
    .select(`
      role,
      crews!inner (
        id, name, description, cover_image_url, invite_code, created_by
      )
    `)
    .eq("user_id", userId);

  if (error) {
    console.error("[getMyCrews] error:", error.message);
    return [];
  }

  const crews: Crew[] = [];

  for (const row of data ?? []) {
    const c = row.crews as unknown as {
      id: string;
      name: string;
      description: string;
      cover_image_url: string | null;
      invite_code: string;
      created_by: string;
    };
    if (!c) continue;

    // Get member + event counts
    const [memberCount, eventCount] = await Promise.all([
      supabase
        .from("crew_members")
        .select("id", { count: "exact", head: true })
        .eq("crew_id", c.id),
      supabase
        .from("events")
        .select("id", { count: "exact", head: true })
        .eq("crew_id", c.id),
    ]);

    crews.push({
      id: c.id,
      name: c.name,
      description: c.description,
      coverImageUrl: c.cover_image_url,
      inviteCode: c.invite_code,
      createdBy: c.created_by,
      memberCount: memberCount.count ?? 0,
      eventCount: eventCount.count ?? 0,
      role: row.role as CrewRole,
    });
  }

  return crews;
}

/**
 * Fetch a single crew by ID with the user's role.
 */
export async function getCrewById(
  supabase: SupabaseClient<Database>,
  crewId: string,
  userId: string,
): Promise<Crew | null> {
  const [crewResult, memberResult, memberCountResult, eventCountResult] =
    await Promise.all([
      supabase
        .from("crews")
        .select("id, name, description, cover_image_url, invite_code, created_by")
        .eq("id", crewId)
        .single(),
      supabase
        .from("crew_members")
        .select("role")
        .eq("crew_id", crewId)
        .eq("user_id", userId)
        .single(),
      supabase
        .from("crew_members")
        .select("id", { count: "exact", head: true })
        .eq("crew_id", crewId),
      supabase
        .from("events")
        .select("id", { count: "exact", head: true })
        .eq("crew_id", crewId),
    ]);

  if (crewResult.error || !crewResult.data) return null;

  const c = crewResult.data;

  return {
    id: c.id,
    name: c.name,
    description: c.description,
    coverImageUrl: c.cover_image_url,
    inviteCode: c.invite_code,
    createdBy: c.created_by,
    memberCount: memberCountResult.count ?? 0,
    eventCount: eventCountResult.count ?? 0,
    role: (memberResult.data?.role as CrewRole) ?? "member",
  };
}

/**
 * Fetch crew members with profile info.
 */
export async function getCrewMembers(
  supabase: SupabaseClient<Database>,
  crewId: string,
): Promise<CrewMember[]> {
  const { data, error } = await supabase
    .from("crew_members")
    .select(`
      id, user_id, role, joined_at,
      profiles!crew_members_user_id_fkey ( display_name, avatar_url )
    `)
    .eq("crew_id", crewId)
    .order("joined_at", { ascending: true });

  if (error) {
    console.error("[getCrewMembers] error:", error.message);
    return [];
  }

  return (data ?? []).map((row) => {
    const profile = row.profiles as unknown as {
      display_name: string;
      avatar_url: string | null;
    } | null;

    return {
      id: row.id,
      userId: row.user_id,
      name: profile?.display_name ?? "멤버",
      avatar: profile?.avatar_url ?? null,
      role: row.role as CrewRole,
      joinedAt: row.joined_at,
    };
  });
}

/**
 * Fetch feed events for a crew.
 */
export async function getCrewFeedEvents(
  supabase: SupabaseClient<Database>,
  crewId: string,
): Promise<CrewFeedEvent[]> {
  const { data, error } = await supabase
    .from("events")
    .select(`
      id, title, datetime, location, mood, cover_image_url,
      host_id,
      profiles!events_host_id_fkey ( display_name ),
      guest_states ( id ),
      event_comments ( id ),
      media_timeline ( thumbnail_path )
    `)
    .eq("crew_id", crewId)
    .order("datetime", { ascending: false })
    .limit(30);

  if (error) {
    console.error("[getCrewFeedEvents] error:", error.message);
    return [];
  }

  return (data ?? []).map((row) => {
    const host = row.profiles as unknown as { display_name: string } | null;
    const guests = row.guest_states as unknown as { id: string }[] | null;
    const comments = row.event_comments as unknown as { id: string }[] | null;
    const photos = row.media_timeline as unknown as
      | { thumbnail_path: string | null }[]
      | null;

    return {
      id: row.id,
      title: row.title,
      datetime: row.datetime,
      location: row.location,
      mood: row.mood as EventMood,
      coverImage: row.cover_image_url,
      hostName: host?.display_name ?? "호스트",
      guestCount: guests?.length ?? 0,
      commentCount: comments?.length ?? 0,
      photoCount: photos?.length ?? 0,
      photos: (photos ?? [])
        .slice(0, 4)
        .map((p) => p.thumbnail_path)
        .filter((p): p is string => p != null),
    };
  });
}
