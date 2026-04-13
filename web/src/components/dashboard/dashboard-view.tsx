"use client";

import { useMemo } from "react";
import type { EventDetail } from "@/lib/types";
import type { MoodTemplate } from "@/lib/types";
import { getMoodTemplate } from "@/lib/mood-templates";
import { useRealtimeGuests } from "@/hooks/use-realtime-guests";
import { AttendanceSummary } from "./attendance-summary";
import { GuestList } from "./guest-list";

interface DashboardViewProps {
  event: EventDetail;
}

function EventHeader({
  event,
  mood,
}: {
  event: EventDetail;
  mood: MoodTemplate;
}) {
  const formattedDate = new Date(event.datetime).toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <div className="space-y-1">
      <p className="text-xs font-medium" style={{ color: mood.colorTheme.primary }}>
        {mood.emoji} {mood.label}
      </p>
      <h1 className="text-xl font-bold">{event.title}</h1>
      <p className="text-sm text-gray-500">
        {formattedDate} · {event.location}
      </p>
    </div>
  );
}

export function DashboardView({ event }: DashboardViewProps) {
  const mood = useMemo(() => getMoodTemplate(event.mood), [event.mood]);
  const { guests, counts, isLoading } = useRealtimeGuests(event.id);

  if (!mood) return null;

  return (
    <div className="flex min-h-dvh flex-col">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-2xl items-center justify-between px-4 xl:max-w-6xl">
          <span className="text-sm font-medium">모먼트</span>
          <span className="text-xs text-gray-400">호스트 대시보드</span>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto w-full max-w-2xl flex-1 px-4 py-6 md:py-8 xl:max-w-6xl xl:py-10">
        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <div
              className="h-8 w-8 animate-spin rounded-full border-2 border-t-transparent"
              style={{ borderColor: mood.colorTheme.primary, borderTopColor: "transparent" }}
            />
          </div>
        ) : (
          <div className="xl:grid xl:grid-cols-[340px_1fr] xl:gap-10">
            {/* Left sidebar (desktop) / top section (mobile): event info + summary */}
            <div className="space-y-8 xl:sticky xl:top-20 xl:self-start">
              {/* Event info */}
              <EventHeader event={event} mood={mood} />

              {/* Attendance counts */}
              <section>
                <h2 className="mb-3 text-sm font-semibold text-gray-700">
                  참석 현황
                </h2>
                <AttendanceSummary counts={counts} mood={mood} />
              </section>

              {/* Photo timeline link */}
              <section>
                <a
                  href={`/event/${event.id}/photos`}
                  className="flex items-center justify-between rounded-xl border p-4 transition-colors hover:bg-gray-50"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-lg">📸</span>
                    <div>
                      <p className="text-sm font-semibold">사진 타임라인</p>
                      <p className="text-xs text-gray-400">
                        모임 사진을 확인하고 공유하세요
                      </p>
                    </div>
                  </div>
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="text-gray-300"
                  >
                    <path d="m9 18 6-6-6-6" />
                  </svg>
                </a>
              </section>

            </div>

            {/* Right column (desktop) / below summary (mobile): guest list */}
            <section className="mt-8 xl:mt-0">
              <h2 className="mb-3 text-sm font-semibold text-gray-700">
                게스트 목록
                <span className="ml-2 text-xs font-normal text-gray-400">
                  {guests.length}명
                </span>
              </h2>
              <GuestList guests={guests} accentColor={mood.colorTheme.primary} />
            </section>
          </div>
        )}
      </main>
    </div>
  );
}
