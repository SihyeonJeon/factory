"use client";

import { useRef, useState, useCallback } from "react";
import type { TimelinePhoto } from "@/lib/types";

interface PhotoUploadButtonProps {
  eventId: string;
  currentCount: number;
  maxPhotos: number;
  accentColor: string;
  onUpload: (photo: TimelinePhoto) => void;
}

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const ACCEPTED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/heic"];

export function PhotoUploadButton({
  eventId,
  currentCount,
  maxPhotos,
  accentColor,
  onUpload,
}: PhotoUploadButtonProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const remaining = maxPhotos - currentCount;
  const isDisabled = remaining <= 0 || uploading;

  const handleFiles = useCallback(
    async (files: FileList | null) => {
      if (!files || files.length === 0) return;
      setError(null);

      const filesToProcess = Array.from(files).slice(0, remaining);

      for (const file of filesToProcess) {
        if (!ACCEPTED_TYPES.includes(file.type)) {
          setError("JPG, PNG, WebP 이미지만 업로드할 수 있어요");
          continue;
        }
        if (file.size > MAX_FILE_SIZE) {
          setError("10MB 이하의 이미지만 업로드할 수 있어요");
          continue;
        }

        setUploading(true);

        // Get image dimensions before upload
        const objectUrl = URL.createObjectURL(file);
        const img = new Image();
        const dimensions = await new Promise<{ w: number; h: number }>(
          (resolve) => {
            img.onload = () => resolve({ w: img.naturalWidth, h: img.naturalHeight });
            img.onerror = () => resolve({ w: 800, h: 800 });
            img.src = objectUrl;
          }
        );
        URL.revokeObjectURL(objectUrl);

        // Upload via API route
        const formData = new FormData();
        formData.append("file", file);
        formData.append("eventId", eventId);
        formData.append("width", String(dimensions.w));
        formData.append("height", String(dimensions.h));

        const res = await fetch("/api/media/upload", {
          method: "POST",
          body: formData,
        });

        if (!res.ok) {
          const body = await res.json();
          setError(body.error ?? "업로드에 실패했어요");
          setUploading(false);
          continue;
        }

        const uploaded = await res.json();

        const photo: TimelinePhoto = {
          id: uploaded.id,
          eventId,
          url: uploaded.url,
          thumbnailUrl: uploaded.thumbnailUrl,
          uploaderName: uploaded.uploaderName ?? "나",
          uploaderAvatar: uploaded.uploaderAvatar ?? null,
          uploadedAt: uploaded.uploadedAt,
          width: uploaded.width ?? dimensions.w,
          height: uploaded.height ?? dimensions.h,
        };

        onUpload(photo);
        setUploading(false);
      }

      // Reset input so same file can be selected again
      if (inputRef.current) inputRef.current.value = "";
    },
    [eventId, onUpload, remaining]
  );

  return (
    <div className="flex flex-col items-center gap-2">
      <button
        type="button"
        disabled={isDisabled}
        onClick={() => inputRef.current?.click()}
        className="flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all active:scale-95 disabled:opacity-40 disabled:active:scale-100"
        style={{ backgroundColor: isDisabled ? "#9CA3AF" : accentColor }}
      >
        {uploading ? (
          <>
            <div className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />
            업로드 중...
          </>
        ) : (
          <>
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="17 8 12 3 7 8" />
              <line x1="12" y1="3" x2="12" y2="15" />
            </svg>
            사진 올리기
          </>
        )}
      </button>

      <p className="text-xs text-gray-400">
        {remaining > 0
          ? `${remaining}장 더 올릴 수 있어요`
          : "최대 업로드 수에 도달했어요"}
      </p>

      {error && (
        <p className="text-xs text-red-500">{error}</p>
      )}

      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/heic"
        multiple
        className="hidden"
        onChange={(e) => handleFiles(e.target.files)}
      />
    </div>
  );
}
