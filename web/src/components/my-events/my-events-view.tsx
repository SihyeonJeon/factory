"use client";

import { useMemo } from "react";
import Link from "next/link";
import type { EventSummary } from "@/lib/queries";
import { getMoodTemplate } from "@/lib/mood-templates";

interface MyEventsViewProps {
  events: EventSummary[];
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
    weekday: "short",
  });
}

function EventCard({ event }: { event: EventSummary }) {
  const mood = getMoodTemplate(event.mood);
  const isPast = new Date(event.datetime) < new Date();

  return (
    <Link
      href={event.role === "host" ? `/dashboard/${event.id}` : `/event/${event.id}`}
      className={`group block rounded-2xl border bg-white p-4 transition-all hover:shadow-md ${
        isPast ? "opacity-70" : ""
      }`}
    >
      <div className="flex items-start gap-3">
        {/* Mood indicator */}
        <div
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-lg"
          style={{ backgroundColor: mood?.colorTheme.bg ?? "#f5f5f5" }}
        >
          {mood?.emoji ?? "📌"}
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <h3 className="truncate text-sm font-semibold group-hover:underline">
              {event.title}
            </h3>
            {event.role === "host" && (
              <span
                className="shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium text-white"
                style={{ backgroundColor: mood?.colorTheme.primary ?? "#666" }}
              >
                호스트
              </span>
            )}
          </div>
          <p className="mt-0.5 text-xs text-gray-500">
            {formatDate(event.datetime)}
            {event.location ? ` · ${event.location}` : ""}
          </p>
          <p className="mt-1 text-xs text-gray-400">
            {event.hostName} · 게스트 {event.guestCount}명
          </p>
        </div>

        {/* Arrow */}
        <svg
          aria-hidden="true"
          className="mt-1 h-4 w-4 shrink-0 text-gray-300 transition-colors group-hover:text-gray-500"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m9 18 6-6-6-6" />
        </svg>
      </div>
    </Link>
  );
}

export function MyEventsView({ events }: MyEventsViewProps) {
  const now = useMemo(() => new Date(), []);
  const upcoming = useMemo(
    () => events.filter((e) => new Date(e.datetime) >= now),
    [events, now],
  );
  const past = useMemo(
    () => events.filter((e) => new Date(e.datetime) < now),
    [events, now],
  );

  return (
    <div className="mx-auto min-h-dvh w-full max-w-2xl px-4 py-6 md:py-10">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">내 이벤트</h1>
        <Link
          href="/create"
          className="inline-flex h-9 items-center rounded-lg bg-primary px-4 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
        >
          + 새 이벤트
        </Link>
      </div>

      {events.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <p className="text-lg font-medium text-gray-400">
            아직 이벤트가 없어요
          </p>
          <p className="mt-2 text-sm text-gray-400">
            첫 이벤트를 만들어 친구들을 초대해보세요!
          </p>
          <Link
            href="/create"
            className="mt-6 inline-flex h-12 items-center rounded-xl bg-primary px-8 text-base font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
          >
            이벤트 만들기
          </Link>
        </div>
      ) : (
        <>
          {/* Upcoming */}
          {upcoming.length > 0 && (
            <section className="mb-8">
              <h2 className="mb-3 text-sm font-semibold text-gray-500">
                다가오는 이벤트 ({upcoming.length})
              </h2>
              <div className="space-y-3">
                {upcoming.map((event) => (
                  <EventCard key={event.id} event={event} />
                ))}
              </div>
            </section>
          )}

          {/* Past */}
          {past.length > 0 && (
            <section>
              <h2 className="mb-3 text-sm font-semibold text-gray-500">
                지난 이벤트 ({past.length})
              </h2>
              <div className="space-y-3">
                {past.map((event) => (
                  <EventCard key={event.id} event={event} />
                ))}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  );
}
