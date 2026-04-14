import Link from "next/link";
import type { CrewFeedEvent } from "@/lib/types";
import { getMoodTemplate } from "@/lib/mood-templates";

interface CrewFeedCardProps {
  event: CrewFeedEvent;
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

export function CrewFeedCard({ event }: CrewFeedCardProps) {
  const mood = getMoodTemplate(event.mood);
  const isPast = new Date(event.datetime) < new Date();

  return (
    <Link
      href={`/event/${event.id}`}
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
          <h3 className="truncate text-sm font-semibold group-hover:underline">
            {event.title}
          </h3>
          <p className="mt-0.5 text-xs text-gray-500">
            {formatDate(event.datetime)}
            {event.location ? ` · ${event.location}` : ""}
          </p>
          <p className="mt-1 text-xs text-gray-400">
            {event.hostName} · 게스트 {event.guestCount}명
          </p>

          {/* Stats row */}
          <div className="mt-2 flex items-center gap-3 text-xs text-gray-400">
            {event.commentCount > 0 && (
              <span className="flex items-center gap-1">
                <CommentIcon />
                {event.commentCount}
              </span>
            )}
            {event.photoCount > 0 && (
              <span className="flex items-center gap-1">
                <PhotoIcon />
                {event.photoCount}
              </span>
            )}
          </div>

          {/* Photo thumbnails */}
          {event.photos.length > 0 && (
            <div className="mt-2 flex gap-1.5">
              {event.photos.map((url, i) => (
                <div
                  key={i}
                  className="h-12 w-12 overflow-hidden rounded-lg bg-gray-100"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt=""
                    className="h-full w-full object-cover"
                    loading="lazy"
                  />
                </div>
              ))}
            </div>
          )}
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

function CommentIcon() {
  return (
    <svg
      aria-hidden="true"
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z" />
    </svg>
  );
}

function PhotoIcon() {
  return (
    <svg
      aria-hidden="true"
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <rect width="18" height="18" x="3" y="3" rx="2" ry="2" />
      <circle cx="9" cy="9" r="2" />
      <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" />
    </svg>
  );
}
