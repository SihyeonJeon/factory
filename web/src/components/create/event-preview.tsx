"use client";

import { Badge } from "@/components/ui/badge";
import type { EventFormData, MoodTemplate } from "@/lib/types";

interface EventPreviewProps {
  data: EventFormData;
  mood: MoodTemplate;
}

function formatDateTime(datetime: string): string {
  if (!datetime) return "";
  const date = new Date(datetime);
  return date.toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function EventPreview({ data, mood }: EventPreviewProps) {
  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">미리보기</h2>
        <p className="text-muted-foreground text-sm">
          카카오톡에 공유될 이벤트 페이지입니다
        </p>
      </div>

      {/* Event card preview */}
      <div className="mx-auto max-w-sm overflow-hidden rounded-2xl border shadow-lg md:max-w-md">
        {/* Cover image */}
        <div
          className="relative aspect-[16/9] w-full"
          style={{ backgroundColor: mood.colorTheme.bg }}
        >
          {data.coverImage ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={data.coverImage}
              alt="커버"
              className="h-full w-full object-cover"
            />
          ) : (
            <div className="flex h-full items-center justify-center">
              <span className="text-6xl">{mood.emoji}</span>
            </div>
          )}
          <Badge
            className="absolute top-3 left-3 border-0"
            style={{
              backgroundColor: mood.colorTheme.primary,
              color: "#fff",
            }}
          >
            {mood.emoji} {mood.label}
          </Badge>
        </div>

        {/* Event info */}
        <div className="space-y-3 p-5">
          <h3 className="text-lg font-bold leading-tight">
            {data.title || "모임 이름"}
          </h3>

          {data.datetime && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <CalendarIcon />
              <span>{formatDateTime(data.datetime)}</span>
            </div>
          )}

          {data.location && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <MapPinIcon />
              <span>{data.location}</span>
            </div>
          )}

          {data.description && (
            <p className="text-sm text-muted-foreground leading-relaxed">
              {data.description}
            </p>
          )}

          {/* Mock RSVP button */}
          <button
            type="button"
            disabled
            className="mt-2 w-full rounded-xl py-3 text-sm font-semibold text-white transition-colors"
            style={{ backgroundColor: mood.colorTheme.primary }}
          >
            참석 여부 응답하기
          </button>
        </div>
      </div>
    </div>
  );
}

function CalendarIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <rect width="18" height="18" x="3" y="4" rx="2" ry="2" />
      <line x1="16" x2="16" y1="2" y2="6" />
      <line x1="8" x2="8" y1="2" y2="6" />
      <line x1="3" x2="21" y1="10" y2="10" />
    </svg>
  );
}

function MapPinIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}
