import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getEventById } from "@/lib/queries";
import { SettlementView } from "@/components/settlement/settlement-view";

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
    title: `정산 — ${event.title} — 모먼트`,
    robots: { index: false },
  };
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function SettlementPage({ params }: Props) {
  const { id } = await params;
  if (!UUID_RE.test(id)) notFound();

  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: event } = await supabase
    .from("events")
    .select("id, host_id, title")
    .eq("id", id)
    .single();

  if (!event) {
    notFound();
  }

  if (event.host_id !== user.id) {
    redirect(`/event/${id}`);
  }

  const eventDetail = await getEventById(supabase, id);
  if (!eventDetail) {
    notFound();
  }

  // Fetch existing settlement if any
  const { data: settlement } = await supabase
    .from("settlements")
    .select("*")
    .eq("event_id", id)
    .single();

  return (
    <SettlementView
      event={eventDetail}
      initialSettlement={settlement ?? null}
    />
  );
}
