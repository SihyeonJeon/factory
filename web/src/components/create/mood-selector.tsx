"use client";

import { cn } from "@/lib/utils";
import type { EventMood } from "@/lib/types";
import { MOOD_TEMPLATES } from "@/lib/mood-templates";

interface MoodSelectorProps {
  selected: EventMood | null;
  onSelect: (mood: EventMood) => void;
}

export function MoodSelector({ selected, onSelect }: MoodSelectorProps) {
  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">
          어떤 모임인가요?
        </h2>
        <p className="text-muted-foreground text-sm">
          모임 분위기에 맞는 템플릿을 선택하세요
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
        {MOOD_TEMPLATES.map((mood) => (
          <button
            key={mood.id}
            type="button"
            onClick={() => onSelect(mood.id)}
            className={cn(
              "flex flex-col items-center gap-2 rounded-2xl border-2 p-5 transition-all active:scale-[0.97]",
              "hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
              selected === mood.id
                ? "border-current shadow-md"
                : "border-border hover:border-muted-foreground/30"
            )}
            style={
              selected === mood.id
                ? {
                    borderColor: mood.colorTheme.primary,
                    backgroundColor: mood.colorTheme.bg,
                    color: mood.colorTheme.primary,
                  }
                : undefined
            }
          >
            <span className="text-4xl" role="img" aria-label={mood.label}>
              {mood.emoji}
            </span>
            <span
              className={cn(
                "text-sm font-medium",
                selected === mood.id
                  ? "text-current"
                  : "text-foreground"
              )}
            >
              {mood.label}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
