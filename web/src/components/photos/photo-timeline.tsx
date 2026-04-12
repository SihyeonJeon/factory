"use client";

import { useState, useMemo } from "react";
import type { TimelinePhoto } from "@/lib/types";

interface PhotoTimelineProps {
  photos: TimelinePhoto[];
  accentColor: string;
  onOpenViewer: (index: number) => void;
}

interface TimelineGroup {
  label: string;
  photos: { photo: TimelinePhoto; globalIndex: number }[];
}

function groupByTime(photos: TimelinePhoto[]): TimelineGroup[] {
  const groups: Map<string, TimelineGroup> = new Map();

  photos.forEach((photo, globalIndex) => {
    const date = new Date(photo.uploadedAt);
    const hour = date.getHours();
    let label: string;
    if (hour < 12) label = "오전";
    else if (hour < 18) label = "오후";
    else label = "저녁";

    const dateStr = date.toLocaleDateString("ko-KR", {
      month: "long",
      day: "numeric",
    });
    const key = `${dateStr} ${label}`;

    if (!groups.has(key)) {
      groups.set(key, { label: key, photos: [] });
    }
    groups.get(key)!.photos.push({ photo, globalIndex });
  });

  return Array.from(groups.values());
}

function PhotoThumbnail({
  photo,
  index,
  onOpen,
}: {
  photo: TimelinePhoto;
  index: number;
  onOpen: (i: number) => void;
}) {
  const [loaded, setLoaded] = useState(false);

  return (
    <button
      type="button"
      onClick={() => onOpen(index)}
      className="group relative w-full overflow-hidden rounded-xl bg-gray-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
      style={{ aspectRatio: "1 / 1" }}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={photo.thumbnailUrl}
        alt={`${photo.uploaderName}님이 올린 사진`}
        loading="lazy"
        onLoad={() => setLoaded(true)}
        className={`absolute inset-0 h-full w-full object-cover transition-opacity duration-300 ${
          loaded ? "opacity-100" : "opacity-0"
        }`}
      />
      {!loaded && (
        <div className="absolute inset-0 animate-pulse bg-gray-200" />
      )}
      {/* Uploader badge */}
      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/50 to-transparent p-2 opacity-0 transition-opacity group-hover:opacity-100 group-focus-visible:opacity-100">
        <span className="text-xs font-medium text-white">
          {photo.uploaderName}
        </span>
      </div>
    </button>
  );
}

export function PhotoTimeline({
  photos,
  accentColor,
  onOpenViewer,
}: PhotoTimelineProps) {
  const groups = useMemo(() => groupByTime(photos), [photos]);

  if (photos.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <div className="mb-3 text-4xl">📷</div>
        <p className="text-sm font-medium text-gray-500">아직 사진이 없어요</p>
        <p className="mt-1 text-xs text-gray-400">
          모임의 순간을 공유해보세요
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {groups.map((group) => (
        <section key={group.label}>
          <div className="mb-3 flex items-center gap-2">
            <div
              className="h-2 w-2 rounded-full"
              style={{ backgroundColor: accentColor }}
            />
            <h3 className="text-xs font-semibold text-gray-500">
              {group.label}
            </h3>
          </div>
          <div className="grid grid-cols-2 gap-1.5 md:grid-cols-3 xl:grid-cols-4">
            {group.photos.map(({ photo, globalIndex }) => (
              <PhotoThumbnail
                key={photo.id}
                photo={photo}
                index={globalIndex}
                onOpen={onOpenViewer}
              />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
