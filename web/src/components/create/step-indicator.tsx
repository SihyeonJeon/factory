"use client";

import { cn } from "@/lib/utils";

interface StepIndicatorProps {
  current: number;
  total: number;
}

const STEP_LABELS = ["무드", "커버", "정보", "미리보기"];

export function StepIndicator({ current, total }: StepIndicatorProps) {
  return (
    <div className="flex items-center justify-center gap-2">
      {Array.from({ length: total }, (_, i) => (
        <div key={i} className="flex items-center gap-2">
          <div className="flex flex-col items-center gap-1">
            <div
              className={cn(
                "flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold transition-colors",
                i < current
                  ? "bg-primary text-primary-foreground"
                  : i === current
                    ? "bg-primary text-primary-foreground ring-2 ring-primary/30 ring-offset-2"
                    : "bg-muted text-muted-foreground"
              )}
            >
              {i < current ? (
                <CheckIcon />
              ) : (
                i + 1
              )}
            </div>
            <span
              className={cn(
                "text-[11px]",
                i <= current
                  ? "font-medium text-foreground"
                  : "text-muted-foreground"
              )}
            >
              {STEP_LABELS[i]}
            </span>
          </div>
          {i < total - 1 && (
            <div
              className={cn(
                "mb-5 h-px w-6 sm:w-10",
                i < current ? "bg-primary" : "bg-border"
              )}
            />
          )}
        </div>
      ))}
    </div>
  );
}

function CheckIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="3"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
