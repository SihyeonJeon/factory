import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getEventById } from "@/lib/queries";
import { DashboardView } from "@/components/dashboard/dashboard-view";

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createServerSupabaseClient();

  // Verify host before exposing event title in metadata
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return { title: "대시보드 — 모먼트", robots: { index: false } };
  }

  const event = await getEventById(supabase, id);
  if (!event || event.hostId !== user.id) {
    return { title: "대시보드 — 모먼트", robots: { index: false } };
  }

  return {
    title: `대시보드 — ${event.title} — 모먼트`,
    description: "호스트 대시보드: 참석 현황 및 게스트 관리",
    robots: { index: false },
  };
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function DashboardPage({ params }: Props) {
  const { id } = await params;
  if (!UUID_RE.test(id)) notFound();

  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const eventDetail = await getEventById(supabase, id);

  if (!eventDetail) {
    notFound();
  }

  if (eventDetail.hostId !== user.id) {
    redirect(`/event/${id}`);
  }

  return <DashboardView event={eventDetail} />;
}
