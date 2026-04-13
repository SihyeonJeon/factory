"use client";

import { cn } from "@/lib/utils";
import type { GuestRsvp, MoodTemplate } from "@/lib/types";

interface RsvpDetailsFormProps {
  rsvp: GuestRsvp;
  onUpdate: (partial: Partial<GuestRsvp>) => void;
  mood: MoodTemplate;
  hasFee: boolean;
}

export function RsvpDetailsForm({
  rsvp,
  onUpdate,
  mood,
  hasFee,
}: RsvpDetailsFormProps) {
  if (rsvp.status !== "attending") return null;

  return (
    <div className="space-y-5">
      {/* Companion count */}
      <div className="space-y-2">
        <label className="text-sm font-semibold">동행 인원</label>
        <p className="text-xs text-muted-foreground">
          본인 포함하지 않고 함께 오는 분 수를 선택해 주세요
        </p>
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() =>
              onUpdate({
                companionCount: Math.max(0, rsvp.companionCount - 1),
              })
            }
            disabled={rsvp.companionCount === 0}
            className={cn(
              "flex h-10 w-10 items-center justify-center rounded-full border-2 text-lg font-semibold transition-colors",
              rsvp.companionCount === 0
                ? "border-muted text-muted-foreground"
                : "border-border hover:bg-muted"
            )}
          >
            -
          </button>
          <span className="min-w-[2.5rem] text-center text-xl font-bold">
            {rsvp.companionCount}
          </span>
          <button
            type="button"
            onClick={() =>
              onUpdate({
                companionCount: Math.min(10, rsvp.companionCount + 1),
              })
            }
            disabled={rsvp.companionCount >= 10}
            className={cn(
              "flex h-10 w-10 items-center justify-center rounded-full border-2 text-lg font-semibold transition-colors",
              rsvp.companionCount >= 10
                ? "border-muted text-muted-foreground"
                : "border-border hover:bg-muted"
            )}
          >
            +
          </button>
          <span className="text-sm text-muted-foreground">명</span>
        </div>
      </div>

      {/* Fee intention */}
      {hasFee && (
        <div className="space-y-2">
          <label className="text-sm font-semibold">회비 납부 의사</label>
          <p className="text-xs text-muted-foreground">
            모임 회비가 있습니다. 납부 의사를 알려주세요
          </p>
          <div className="grid grid-cols-2 gap-2">
            {(
              [
                { value: "will_pay", label: "납부할게요" },
                { value: "undecided", label: "아직 모르겠어요" },
              ] as const
            ).map(({ value, label }) => {
              const isSelected = rsvp.feeIntention === value;
              return (
                <button
                  key={value}
                  type="button"
                  onClick={() => onUpdate({ feeIntention: value })}
                  className={cn(
                    "rounded-xl border-2 px-4 py-3 text-sm font-medium transition-all",
                    "active:scale-[0.97]",
                    isSelected
                      ? "border-transparent shadow-sm"
                      : "border-border bg-background hover:border-muted-foreground/30"
                  )}
                  style={
                    isSelected
                      ? {
                          backgroundColor: mood.colorTheme.bg,
                          borderColor: mood.colorTheme.primary,
                          color: mood.colorTheme.accent,
                        }
                      : undefined
                  }
                >
                  {label}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
