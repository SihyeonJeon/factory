import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getEventById } from "@/lib/queries";
import { getMoodTemplate } from "@/lib/mood-templates";
import { EventRsvpFlow } from "@/components/rsvp/event-rsvp-flow";

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

  const mood = getMoodTemplate(event.mood);

  const formattedDate = new Date(event.datetime).toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
  });

  return {
    title: `${event.title} — 모먼트`,
    description: `${formattedDate} · ${event.location}`,
    openGraph: {
      title: event.title,
      description: `${formattedDate} · ${event.location}`,
      type: "website",
      siteName: "모먼트",
    },
    other: {
      "og:title": event.title,
      "og:description": `${formattedDate} · ${event.location}`,
      ...(mood ? { "theme-color": mood.colorTheme.primary } : {}),
    },
  };
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function EventPage({ params }: Props) {
  const { id } = await params;
  if (!UUID_RE.test(id)) notFound();

  const supabase = await createServerSupabaseClient();
  const event = await getEventById(supabase, id);

  if (!event) {
    notFound();
  }

  // Fetch current user
  const { data: { user } } = await supabase.auth.getUser();

  const currentUserId = user?.id ?? null;
  const isHost = currentUserId === event.hostId;

  return (
    <EventRsvpFlow
      event={event}
      currentUserId={currentUserId}
      isHost={isHost}
    />
  );
}
