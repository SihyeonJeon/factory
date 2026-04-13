"use client";

import { useState, useMemo, useCallback } from "react";
import type { EventDetail, TimelinePhoto } from "@/lib/types";
import { getMoodTemplate } from "@/lib/mood-templates";
import { PhotoTimeline } from "./photo-timeline";
import { PhotoSwipeViewer } from "./photo-swipe-viewer";
import { PhotoUploadButton } from "./photo-upload-button";

const MAX_PHOTOS_PER_EVENT = 10;

interface PhotosPageViewProps {
  event: EventDetail;
  initialPhotos: TimelinePhoto[];
}

export function PhotosPageView({ event, initialPhotos }: PhotosPageViewProps) {
  const mood = useMemo(() => getMoodTemplate(event.mood), [event.mood]);
  const [photos, setPhotos] = useState<TimelinePhoto[]>(initialPhotos);
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);

  const handleUpload = useCallback((photo: TimelinePhoto) => {
    setPhotos((prev) => [...prev, photo]);
  }, []);

  const handleOpenViewer = useCallback((index: number) => {
    setViewerIndex(index);
  }, []);

  const handleCloseViewer = useCallback(() => {
    setViewerIndex(null);
  }, []);

  if (!mood) return null;

  const formattedDate = new Date(event.datetime).toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
  });

  return (
    <div className="flex min-h-dvh flex-col" style={{ backgroundColor: mood.colorTheme.bg }}>
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-2xl items-center justify-between px-4 xl:max-w-5xl">
          <a
            href={`/event/${event.id}`}
            className="flex items-center gap-1 text-sm text-gray-500 transition-colors hover:text-gray-800"
          >
            <svg
              aria-hidden="true"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="m15 18-6-6 6-6" />
            </svg>
            이벤트로 돌아가기
          </a>
          <span className="text-xs text-gray-400">{photos.length}장</span>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto w-full max-w-2xl flex-1 px-4 py-6 md:py-8 xl:max-w-5xl">
        {/* Event info */}
        <div className="mb-6 space-y-1">
          <p
            className="text-xs font-medium"
            style={{ color: mood.colorTheme.primary }}
          >
            {mood.emoji} {mood.label}
          </p>
          <h1 className="text-xl font-bold">{event.title}</h1>
          <p className="text-sm text-gray-500">
            {formattedDate} · {event.location}
          </p>
        </div>

        {/* Section title */}
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-sm font-semibold text-gray-700">
            사진 타임라인
          </h2>
        </div>

        {/* Upload */}
        <div className="mb-6">
          <PhotoUploadButton
            eventId={event.id}
            currentCount={photos.length}
            maxPhotos={MAX_PHOTOS_PER_EVENT}
            accentColor={mood.colorTheme.primary}
            onUpload={handleUpload}
          />
        </div>

        {/* Timeline grid */}
        <PhotoTimeline
          photos={photos}
          accentColor={mood.colorTheme.primary}
          onOpenViewer={handleOpenViewer}
        />
      </main>

      {/* Swipe viewer overlay */}
      {viewerIndex !== null && (
        <PhotoSwipeViewer
          photos={photos}
          initialIndex={viewerIndex}
          onClose={handleCloseViewer}
        />
      )}
    </div>
  );
}
