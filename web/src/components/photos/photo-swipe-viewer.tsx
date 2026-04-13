"use client";

import {
  useState,
  useRef,
  useCallback,
  useEffect,
  type TouchEvent as ReactTouchEvent,
} from "react";
import type { TimelinePhoto } from "@/lib/types";

interface PhotoSwipeViewerProps {
  photos: TimelinePhoto[];
  initialIndex: number;
  onClose: () => void;
}

const SWIPE_THRESHOLD = 50;

export function PhotoSwipeViewer({
  photos,
  initialIndex,
  onClose,
}: PhotoSwipeViewerProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [offsetX, setOffsetX] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const [loaded, setLoaded] = useState<Set<number>>(new Set());
  const touchStartX = useRef(0);
  const touchStartY = useRef(0);
  const isHorizontalSwipe = useRef<boolean | null>(null);

  const photo = photos[currentIndex];

  const goTo = useCallback(
    (index: number) => {
      if (index >= 0 && index < photos.length) {
        setCurrentIndex(index);
        setOffsetX(0);
      }
    },
    [photos.length]
  );

  // Keyboard navigation
  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
      if (e.key === "ArrowLeft") goTo(currentIndex - 1);
      if (e.key === "ArrowRight") goTo(currentIndex + 1);
    }
    window.addEventListener("keydown", handleKey);
    return () => window.removeEventListener("keydown", handleKey);
  }, [currentIndex, goTo, onClose]);

  // Lock body scroll when viewer is open
  useEffect(() => {
    const original = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = original;
    };
  }, []);

  const handleTouchStart = (e: ReactTouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
    touchStartY.current = e.touches[0].clientY;
    isHorizontalSwipe.current = null;
    setIsDragging(true);
  };

  const handleTouchMove = (e: ReactTouchEvent) => {
    if (!isDragging) return;

    const dx = e.touches[0].clientX - touchStartX.current;
    const dy = e.touches[0].clientY - touchStartY.current;

    // Determine swipe direction on first significant movement
    if (isHorizontalSwipe.current === null) {
      if (Math.abs(dx) > 8 || Math.abs(dy) > 8) {
        isHorizontalSwipe.current = Math.abs(dx) > Math.abs(dy);
      }
      return;
    }

    if (!isHorizontalSwipe.current) return;

    // Dampen at edges
    const atLeftEdge = currentIndex === 0 && dx > 0;
    const atRightEdge = currentIndex === photos.length - 1 && dx < 0;
    const dampen = atLeftEdge || atRightEdge ? 0.3 : 1;

    setOffsetX(dx * dampen);
  };

  const handleTouchEnd = () => {
    setIsDragging(false);

    if (isHorizontalSwipe.current && Math.abs(offsetX) > SWIPE_THRESHOLD) {
      if (offsetX < 0) goTo(currentIndex + 1);
      else goTo(currentIndex - 1);
    } else {
      setOffsetX(0);
    }
  };

  const handleImageLoad = useCallback((index: number) => {
    setLoaded((prev) => new Set(prev).add(index));
  }, []);

  const formattedTime = new Date(photo.uploadedAt).toLocaleTimeString("ko-KR", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <div
      className="fixed inset-0 z-50 flex flex-col bg-black"
      role="dialog"
      aria-modal="true"
      aria-label="사진 뷰어"
    >
      {/* Top bar */}
      <div className="relative z-10 flex items-center justify-between px-4 py-3">
        <button
          type="button"
          onClick={onClose}
          className="flex h-10 w-10 items-center justify-center rounded-full text-white/80 transition-colors hover:bg-white/10 active:bg-white/20"
          aria-label="닫기"
        >
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M18 6 6 18M6 6l12 12" />
          </svg>
        </button>
        <span className="text-sm font-medium text-white/60">
          {currentIndex + 1} / {photos.length}
        </span>
        <div className="w-10" /> {/* Spacer for centering */}
      </div>

      {/* Photo area */}
      <div
        className="relative flex flex-1 items-center justify-center overflow-hidden"
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        <div
          className="flex h-full w-full items-center justify-center px-4"
          style={{
            transform: `translateX(${offsetX}px)`,
            transition: isDragging ? "none" : "transform 0.25s ease-out",
          }}
        >
          {!loaded.has(currentIndex) && (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-white/30 border-t-white" />
            </div>
          )}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            key={photo.id}
            src={photo.url}
            alt={`${photo.uploaderName}님이 올린 사진`}
            onLoad={() => handleImageLoad(currentIndex)}
            className={`max-h-full max-w-full select-none object-contain transition-opacity duration-200 ${
              loaded.has(currentIndex) ? "opacity-100" : "opacity-0"
            }`}
            draggable={false}
          />
        </div>

        {/* Desktop nav arrows */}
        {currentIndex > 0 && (
          <button
            type="button"
            onClick={() => goTo(currentIndex - 1)}
            className="absolute left-2 top-1/2 hidden -translate-y-1/2 rounded-full bg-black/40 p-2 text-white/80 transition-colors hover:bg-black/60 md:flex"
            aria-label="이전 사진"
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <path d="m15 18-6-6 6-6" />
            </svg>
          </button>
        )}
        {currentIndex < photos.length - 1 && (
          <button
            type="button"
            onClick={() => goTo(currentIndex + 1)}
            className="absolute right-2 top-1/2 hidden -translate-y-1/2 rounded-full bg-black/40 p-2 text-white/80 transition-colors hover:bg-black/60 md:flex"
            aria-label="다음 사진"
          >
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <path d="m9 18 6-6-6-6" />
            </svg>
          </button>
        )}
      </div>

      {/* Bottom info */}
      <div className="px-4 pb-6 pt-3">
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-white/20 text-xs font-semibold text-white">
            {photo.uploaderName[0]}
          </div>
          <div>
            <p className="text-sm font-medium text-white">
              {photo.uploaderName}
            </p>
            <p className="text-xs text-white/50">{formattedTime}</p>
          </div>
        </div>

        {/* Dot indicators */}
        {photos.length <= 20 && (
          <div className="mt-4 flex justify-center gap-1.5">
            {photos.map((_, i) => (
              <button
                key={photos[i].id}
                type="button"
                onClick={() => goTo(i)}
                aria-label={`사진 ${i + 1}`}
                className="flex items-center justify-center"
                style={{ minWidth: 44, minHeight: 44 }}
              >
                <span
                  className={`block h-1.5 rounded-full transition-all ${
                    i === currentIndex
                      ? "w-4 bg-white"
                      : "w-1.5 bg-white/30"
                  }`}
                />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
