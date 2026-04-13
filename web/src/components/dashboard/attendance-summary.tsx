"use client";

import type { AttendanceCounts } from "@/lib/types";
import type { MoodTemplate } from "@/lib/types";

interface AttendanceSummaryProps {
  counts: AttendanceCounts;
  mood: MoodTemplate;
}

const STATUS_META: {
  key: keyof Omit<AttendanceCounts, "totalHeadcount">;
  label: string;
  color: string;
}[] = [
  { key: "attending", label: "참석", color: "text-emerald-600" },
  { key: "declined", label: "불참", color: "text-rose-500" },
  { key: "maybe", label: "미정", color: "text-amber-500" },
  { key: "pending", label: "미응답", color: "text-gray-400" },
];

export function AttendanceSummary({ counts, mood }: AttendanceSummaryProps) {
  return (
    <div className="space-y-4">
      {/* Total headcount banner */}
      <div
        className="flex items-center justify-between rounded-2xl px-5 py-4"
        style={{ backgroundColor: mood.colorTheme.bg }}
      >
        <span className="text-sm font-medium text-gray-700">
          총 예상 인원
        </span>
        <span
          className="text-2xl font-bold"
          style={{ color: mood.colorTheme.primary }}
        >
          {counts.totalHeadcount}
          <span className="ml-1 text-sm font-normal text-gray-500">명</span>
        </span>
      </div>

      {/* Status breakdown grid */}
      <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
        {STATUS_META.map(({ key, label, color }) => (
          <div
            key={key}
            className="flex flex-col items-center gap-1 rounded-xl bg-gray-50 py-3"
          >
            <span className={`text-xl font-bold ${color}`}>
              {counts[key]}
            </span>
            <span className="text-xs text-gray-500">{label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
