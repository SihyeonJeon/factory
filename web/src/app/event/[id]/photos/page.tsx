import type { Metadata } from "next";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getEventPhotos } from "@/lib/queries/media";
import { getMockEvent } from "@/lib/mock-event";
import { PhotosPageView } from "@/components/photos/photos-page-view";
import type { EventDetail } from "@/lib/types";

type Props = {
  params: Promise<{ id: string }>;
};

async function getEventDetail(id: string): Promise<EventDetail> {
  const supabase = await createServerSupabaseClient();
  const { data } = await supabase
    .from("events")
    .select(
      `
      id, title, datetime, location, description, mood,
      cover_image_url, has_fee,
      host:profiles!events_host_id_fkey ( display_name, avatar_url )
    `,
    )
    .eq("id", id)
    .single();

  if (!data) return getMockEvent(id);

  const host = data.host as
    | { display_name: string; avatar_url: string | null }
    | null;

  const { count } = await supabase
    .from("guest_states")
    .select("id", { count: "exact", head: true })
    .eq("event_id", id);

  return {
    id: data.id,
    title: data.title,
    datetime: data.datetime,
    location: data.location,
    description: data.description,
    mood: data.mood,
    coverImage: data.cover_image_url,
    hostName: host?.display_name ?? "",
    hostAvatar: host?.avatar_url ?? null,
    guestCount: count ?? 0,
    hasFee: data.has_fee,
  };
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const event = await getEventDetail(id);

  return {
    title: `사진 타임라인 — ${event.title} — 모먼트`,
    description: `${event.title} 모임의 사진을 확인하세요`,
  };
}

export default async function PhotosPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createServerSupabaseClient();

  const [event, photos] = await Promise.all([
    getEventDetail(id),
    getEventPhotos(supabase, id),
  ]);

  return <PhotosPageView event={event} initialPhotos={photos} />;
}
