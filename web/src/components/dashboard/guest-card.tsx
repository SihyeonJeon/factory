"use client";

import type { DashboardGuest, GuestResponseStatus } from "@/lib/types";
import { Badge } from "@/components/ui/badge";

const STATUS_CONFIG: Record<
  GuestResponseStatus,
  { label: string; variant: "default" | "secondary" | "destructive" | "outline" }
> = {
  attending: { label: "참석", variant: "default" },
  maybe: { label: "미정", variant: "secondary" },
  declined: { label: "불참", variant: "destructive" },
  pending: { label: "미응답", variant: "outline" },
};

function formatRelativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return "방금 전";
  if (minutes < 60) return `${minutes}분 전`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}시간 전`;
  return `${Math.floor(hours / 24)}일 전`;
}

function AvatarFallback({ name }: { name: string }) {
  // Pick a stable hue from the first char
  const hue = (name.charCodeAt(0) * 37) % 360;
  return (
    <div
      className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-semibold text-white"
      style={{ backgroundColor: `hsl(${hue}, 55%, 55%)` }}
    >
      {name.charAt(0)}
    </div>
  );
}

interface GuestCardProps {
  guest: DashboardGuest;
}

export function GuestCard({ guest }: GuestCardProps) {
  const statusCfg = STATUS_CONFIG[guest.status];

  return (
    <div className="flex items-center gap-3 rounded-xl border bg-white px-4 py-3 transition-colors hover:bg-gray-50/60">
      {/* Avatar */}
      {guest.avatar ? (
        <img
          src={guest.avatar}
          alt={guest.name}
          className="h-10 w-10 shrink-0 rounded-full object-cover"
        />
      ) : (
        <AvatarFallback name={guest.name} />
      )}

      {/* Info */}
      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex items-center gap-2">
          <span className="truncate text-sm font-medium">{guest.name}</span>
          {guest.companionCount > 0 && (
            <span className="text-xs text-gray-400">
              +{guest.companionCount}명
            </span>
          )}
        </div>
        <span className="text-xs text-gray-400">
          {guest.respondedAt
            ? formatRelativeTime(guest.respondedAt)
            : "아직 응답 없음"}
        </span>
      </div>

      {/* Status badge */}
      <Badge variant={statusCfg.variant}>{statusCfg.label}</Badge>
    </div>
  );
}
