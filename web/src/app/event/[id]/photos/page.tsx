import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getEventById } from "@/lib/queries";
import { getEventPhotos } from "@/lib/queries/media";
import { PhotosPageView } from "@/components/photos/photos-page-view";

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createServerSupabaseClient();
  const event = await getEventById(supabase, id);

  if (!event) {
    return { title: "이벤트를 찾을 수 없습니다 — 모먼트" };
  }

  return {
    title: `사진 타임라인 — ${event.title} — 모먼트`,
    description: `${event.title} 모임의 사진을 확인하세요`,
  };
}

export default async function PhotosPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createServerSupabaseClient();

  const event = await getEventById(supabase, id);

  if (!event) {
    notFound();
  }

  const photos = await getEventPhotos(supabase, id);

  return <PhotosPageView event={event} initialPhotos={photos} />;
}
