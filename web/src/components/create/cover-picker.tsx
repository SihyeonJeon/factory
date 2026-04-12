"use client";

import { useRef, useCallback } from "react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import type { MoodTemplate } from "@/lib/types";

interface CoverPickerProps {
  coverImage: string | null;
  mood: MoodTemplate;
  onCoverChange: (url: string, file: File | null) => void;
}

export function CoverPicker({
  coverImage,
  mood,
  onCoverChange,
}: CoverPickerProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;
      const objectUrl = URL.createObjectURL(file);
      onCoverChange(objectUrl, file);
    },
    [onCoverChange]
  );

  const handleUseDefault = useCallback(() => {
    onCoverChange(mood.defaultCover, null);
  }, [mood.defaultCover, onCoverChange]);

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">커버 이미지</h2>
        <p className="text-muted-foreground text-sm">
          모임 분위기를 보여줄 이미지를 선택하세요
        </p>
      </div>

      {/* Preview area */}
      <div
        className={cn(
          "relative mx-auto aspect-[16/9] w-full max-w-md overflow-hidden rounded-2xl border-2 border-dashed",
          coverImage ? "border-transparent" : "border-border"
        )}
        style={{ backgroundColor: mood.colorTheme.bg }}
      >
        {coverImage ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={coverImage}
            alt="커버 미리보기"
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full flex-col items-center justify-center gap-2 text-muted-foreground">
            <span className="text-5xl">{mood.emoji}</span>
            <span className="text-sm">이미지를 선택해주세요</span>
          </div>
        )}
      </div>

      {/* Action buttons */}
      <div className="flex flex-col gap-2 sm:flex-row sm:justify-center">
        <Button
          type="button"
          variant="outline"
          size="lg"
          className="h-11 px-6"
          onClick={() => fileInputRef.current?.click()}
        >
          갤러리에서 선택
        </Button>
        <Button
          type="button"
          variant="secondary"
          size="lg"
          className="h-11 px-6"
          onClick={handleUseDefault}
        >
          기본 이미지 사용
        </Button>
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleFileSelect}
      />
    </div>
  );
}
