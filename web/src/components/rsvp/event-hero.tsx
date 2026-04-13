"use client";

import { Badge } from "@/components/ui/badge";
import type { EventDetail, MoodTemplate } from "@/lib/types";

interface EventHeroProps {
  event: EventDetail;
  mood: MoodTemplate;
}

function formatDateTime(datetime: string): string {
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

export function EventHero({ event, mood }: EventHeroProps) {
  return (
    <div className="space-y-5">
      {/* Cover */}
      <div
        className="relative aspect-[16/9] w-full overflow-hidden rounded-2xl"
        style={{ backgroundColor: mood.colorTheme.bg }}
      >
        {event.coverImage ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={event.coverImage}
            alt={event.title}
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full items-center justify-center">
            <span className="text-7xl">{mood.emoji}</span>
          </div>
        )}
        <Badge
          className="absolute top-3 left-3 border-0"
          style={{ backgroundColor: mood.colorTheme.primary, color: "#fff" }}
        >
          {mood.emoji} {mood.label}
        </Badge>
      </div>

      {/* Event info */}
      <div className="space-y-3">
        <h1 className="text-2xl font-bold leading-tight tracking-tight md:text-3xl">
          {event.title}
        </h1>

        {/* Host */}
        <div className="flex items-center gap-2">
          <div
            className="flex h-7 w-7 items-center justify-center rounded-full text-xs font-semibold text-white"
            style={{ backgroundColor: mood.colorTheme.primary }}
          >
            {event.hostName.charAt(0)}
          </div>
          <span className="text-sm text-muted-foreground">
            <span className="font-medium text-foreground">
              {event.hostName}
            </span>
            님의 모임
          </span>
        </div>

        {/* Date & Location */}
        <div className="space-y-2">
          <div className="flex items-center gap-2 text-sm">
            <CalendarIcon />
            <span>{formatDateTime(event.datetime)}</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <MapPinIcon />
            <span>{event.location}</span>
          </div>
          {event.guestCount > 0 && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <UsersIcon />
              <span>{event.guestCount}명 참석 예정</span>
            </div>
          )}
        </div>

        {/* Description */}
        {event.description && (
          <p className="text-sm leading-relaxed text-muted-foreground">
            {event.description}
          </p>
        )}
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
    >
      <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}

function UsersIcon() {
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
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
