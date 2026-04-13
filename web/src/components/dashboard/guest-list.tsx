"use client";

import { useState, useMemo } from "react";
import type { DashboardGuest, GuestResponseStatus } from "@/lib/types";
import { GuestCard } from "./guest-card";

const FILTER_OPTIONS: { key: GuestResponseStatus | "all"; label: string }[] = [
  { key: "all", label: "전체" },
  { key: "attending", label: "참석" },
  { key: "maybe", label: "미정" },
  { key: "declined", label: "불참" },
  { key: "pending", label: "미응답" },
];

interface GuestListProps {
  guests: DashboardGuest[];
  accentColor: string;
}

export function GuestList({ guests, accentColor }: GuestListProps) {
  const [filter, setFilter] = useState<GuestResponseStatus | "all">("all");

  const filtered = useMemo(() => {
    if (filter === "all") return guests;
    return guests.filter((g) => g.status === filter);
  }, [guests, filter]);

  return (
    <div className="space-y-3">
      {/* Filter tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
        {FILTER_OPTIONS.map(({ key, label }) => {
          const isActive = filter === key;
          return (
            <button
              key={key}
              type="button"
              onClick={() => setFilter(key)}
              className="shrink-0 rounded-full px-3.5 py-1.5 text-xs font-medium transition-colors"
              style={
                isActive
                  ? { backgroundColor: accentColor, color: "#fff" }
                  : { backgroundColor: "#f3f4f6", color: "#6b7280" }
              }
            >
              {label}
            </button>
          );
        })}
      </div>

      {/* Cards */}
      <div className="space-y-2 md:grid md:grid-cols-2 md:gap-2 md:space-y-0">
        {filtered.length === 0 && (
          <p className="py-8 text-center text-sm text-gray-400">
            해당하는 게스트가 없습니다
          </p>
        )}
        {filtered.map((guest) => (
          <GuestCard key={guest.id} guest={guest} />
        ))}
      </div>
    </div>
  );
}
