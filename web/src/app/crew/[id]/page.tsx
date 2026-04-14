import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getCrewById, getCrewFeedEvents } from "@/lib/crew-queries";
import { CrewHeader } from "@/components/crew/crew-header";
import { CrewFeedCard } from "@/components/crew/crew-feed-card";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  if (!UUID_RE.test(id)) return { title: "아크를 찾을 수 없습니다 — 모먼트" };

  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { title: "아크 — 모먼트" };

  const crew = await getCrewById(supabase, id, user.id);
  if (!crew) return { title: "아크를 찾을 수 없습니다 — 모먼트" };

  return {
    title: `${crew.name} — 모먼트`,
    robots: { index: false },
  };
}

export default async function CrewPage({ params }: Props) {
  const { id } = await params;
  if (!UUID_RE.test(id)) notFound();

  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect(`/login?next=/crew/${id}`);

  const [crew, feedEvents] = await Promise.all([
    getCrewById(supabase, id, user.id),
    getCrewFeedEvents(supabase, id),
  ]);

  if (!crew) notFound();

  return (
    <div className="mx-auto min-h-dvh w-full max-w-lg px-4 py-6 md:py-10">
      {/* Back link */}
      <Link
        href="/my"
        className="mb-4 inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
      >
        <svg
          aria-hidden="true"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m15 18-6-6 6-6" />
        </svg>
        내 이벤트
      </Link>

      {/* Crew header */}
      <CrewHeader crew={crew} />

      {/* Create event CTA */}
      <div className="mt-6">
        <Link
          href={`/create?crewId=${crew.id}`}
          className="inline-flex h-10 items-center rounded-lg bg-primary px-5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
        >
          + 이벤트 만들기
        </Link>
      </div>

      {/* Feed */}
      <section className="mt-6">
        <h2 className="mb-3 text-sm font-semibold text-gray-500">
          아크 이벤트 ({feedEvents.length})
        </h2>

        {feedEvents.length === 0 ? (
          <div className="rounded-2xl border bg-gray-50 py-12 text-center">
            <p className="text-sm text-gray-400">아직 이벤트가 없어요</p>
            <p className="mt-1 text-xs text-gray-400">
              첫 이벤트를 만들어보세요!
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {feedEvents.map((event) => (
              <CrewFeedCard key={event.id} event={event} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
