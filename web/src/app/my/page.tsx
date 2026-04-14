import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getMyEvents } from "@/lib/queries";
import { getMyCrews } from "@/lib/crew-queries";
import { MyEventsView } from "@/components/my-events/my-events-view";

export const metadata: Metadata = {
  title: "내 이벤트 — 모먼트",
  robots: { index: false },
};

export default async function MyEventsPage() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login?next=/my");

  const [events, crews] = await Promise.all([
    getMyEvents(supabase, user.id),
    getMyCrews(supabase, user.id),
  ]);

  return <MyEventsView events={events} crews={crews} />;
}
