"use client";

import type { GuestRsvp, MoodTemplate } from "@/lib/types";
import { RSVP_STATUS_CONFIG } from "@/lib/types";

interface RsvpConfirmationProps {
  rsvp: GuestRsvp;
  mood: MoodTemplate;
  guestCount: number;
  onReset: () => void;
}

export function RsvpConfirmation({
  rsvp,
  mood,
  guestCount,
  onReset,
}: RsvpConfirmationProps) {
  const config = RSVP_STATUS_CONFIG[rsvp.status];

  return (
    <div className="space-y-6 text-center">
      {/* Confirmation badge */}
      <div
        className="mx-auto flex h-20 w-20 items-center justify-center rounded-full"
        style={{ backgroundColor: mood.colorTheme.bg }}
      >
        <span className="text-4xl">
          {rsvp.status === "attending"
            ? "\u2705"
            : rsvp.status === "declined"
              ? "\u274C"
              : "\u2753"}
        </span>
      </div>

      <div className="space-y-1">
        <h2 className="text-xl font-bold">응답 완료!</h2>
        <p className="text-muted-foreground">
          <span
            className="font-semibold"
            style={{ color: mood.colorTheme.primary }}
          >
            {config.label}
          </span>
          (으)로 응답했습니다
        </p>
      </div>

      {/* Summary */}
      {rsvp.status === "attending" && (
        <div
          className="mx-auto max-w-xs space-y-2 rounded-xl p-4"
          style={{ backgroundColor: mood.colorTheme.bg }}
        >
          {rsvp.companionCount > 0 && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">동행</span>
              <span className="font-medium">+{rsvp.companionCount}명</span>
            </div>
          )}
          {rsvp.feeIntention && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">회비</span>
              <span className="font-medium">
                {rsvp.feeIntention === "will_pay"
                  ? "납부 예정"
                  : "미정"}
              </span>
            </div>
          )}
        </div>
      )}

      {/* Attendee preview */}
      <div className="space-y-2">
        <p className="text-sm text-muted-foreground">
          현재{" "}
          <span className="font-semibold text-foreground">{guestCount}명</span>
          이 참석 예정이에요
        </p>
        <div className="flex justify-center -space-x-2">
          {Array.from({ length: Math.min(guestCount, 5) }).map((_, i) => (
            <div
              key={i}
              className="flex h-9 w-9 items-center justify-center rounded-full border-2 border-background text-xs font-semibold text-white"
              style={{
                backgroundColor: mood.colorTheme.primary,
                opacity: 1 - i * 0.12,
              }}
            >
              {String.fromCharCode(65 + i)}
            </div>
          ))}
          {guestCount > 5 && (
            <div className="flex h-9 w-9 items-center justify-center rounded-full border-2 border-background bg-muted text-xs font-semibold text-muted-foreground">
              +{guestCount - 5}
            </div>
          )}
        </div>
      </div>

      {/* Change response */}
      <button
        type="button"
        onClick={onReset}
        className="text-sm text-muted-foreground underline underline-offset-4 hover:text-foreground transition-colors"
      >
        응답 변경하기
      </button>
    </div>
  );
}
