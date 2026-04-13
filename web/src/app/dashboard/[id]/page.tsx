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
  const event = await getEventById(supabase, id);

  if (!event) {
    return { title: "이벤트를 찾을 수 없습니다 — 모먼트" };
  }

  return {
    title: `대시보드 — ${event.title} — 모먼트`,
    description: "호스트 대시보드: 참석 현황 및 게스트 관리",
    robots: { index: false },
  };
}

export default async function DashboardPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createServerSupabaseClient();

  // Verify the current user is the host of this event
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  // Fetch event and verify host ownership
  const { data: event } = await supabase
    .from("events")
    .select("host_id")
    .eq("id", id)
    .single();

  if (!event) {
    notFound();
  }

  if (event.host_id !== user.id) {
    // Not the host — redirect to the guest-facing event page
    redirect(`/event/${id}`);
  }

  const eventDetail = await getEventById(supabase, id);

  if (!eventDetail) {
    notFound();
  }

  return <DashboardView event={eventDetail} />;
}
