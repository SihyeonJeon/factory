"use client";

import { cn } from "@/lib/utils";
import type { RsvpStatus, MoodTemplate } from "@/lib/types";
import { RSVP_STATUS_CONFIG } from "@/lib/types";

interface RsvpStatusSelectorProps {
  selected: RsvpStatus;
  onSelect: (status: RsvpStatus) => void;
  mood: MoodTemplate;
}

const STATUS_ORDER: RsvpStatus[] = ["attending", "declined", "maybe"];

const STATUS_ICONS: Record<RsvpStatus, React.ReactNode> = {
  attending: <CheckCircleIcon />,
  declined: <XCircleIcon />,
  maybe: <QuestionCircleIcon />,
};

export function RsvpStatusSelector({
  selected,
  onSelect,
  mood,
}: RsvpStatusSelectorProps) {
  return (
    <div className="space-y-3">
      <h2 className="text-lg font-semibold">참석 여부</h2>
      <div className="grid grid-cols-3 gap-2">
        {STATUS_ORDER.map((status) => {
          const config = RSVP_STATUS_CONFIG[status];
          const isSelected = selected === status;

          return (
            <button
              key={status}
              type="button"
              onClick={() => onSelect(status)}
              className={cn(
                "flex flex-col items-center gap-1.5 rounded-xl border-2 px-3 py-4 text-center transition-all",
                "active:scale-[0.97]",
                isSelected
                  ? "border-transparent shadow-md"
                  : "border-border bg-background hover:border-muted-foreground/30"
              )}
              style={
                isSelected
                  ? {
                      backgroundColor: mood.colorTheme.bg,
                      borderColor: mood.colorTheme.primary,
                    }
                  : undefined
              }
            >
              <span
                className={cn("text-xl", !isSelected && "opacity-50")}
                style={
                  isSelected
                    ? { color: mood.colorTheme.primary }
                    : undefined
                }
              >
                {STATUS_ICONS[status]}
              </span>
              <span
                className={cn(
                  "text-sm font-semibold",
                  !isSelected && "text-muted-foreground"
                )}
                style={
                  isSelected
                    ? { color: mood.colorTheme.accent }
                    : undefined
                }
              >
                {config.label}
              </span>
            </button>
          );
        })}
      </div>
      <p className="text-center text-xs text-muted-foreground">
        {RSVP_STATUS_CONFIG[selected].description}
      </p>
    </div>
  );
}

function CheckCircleIcon() {
  return (
    <svg
      width="28"
      height="28"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
      <polyline points="22 4 12 14.01 9 11.01" />
    </svg>
  );
}

function XCircleIcon() {
  return (
    <svg
      width="28"
      height="28"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <line x1="15" y1="9" x2="9" y2="15" />
      <line x1="9" y1="9" x2="15" y2="15" />
    </svg>
  );
}

function QuestionCircleIcon() {
  return (
    <svg
      width="28"
      height="28"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}
