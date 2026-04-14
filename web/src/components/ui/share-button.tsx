"use client";

import { useState, useCallback } from "react";

interface ShareButtonProps {
  title: string;
  text: string;
  url: string;
  accentColor?: string;
  className?: string;
}

export function ShareButton({ title, text, url, accentColor, className }: ShareButtonProps) {
  const [copied, setCopied] = useState(false);

  const handleShare = useCallback(async () => {
    const shareUrl = url.startsWith("http")
      ? url
      : `${window.location.origin}${url}`;

    // Use native share if available (mobile browsers)
    if (navigator.share) {
      try {
        await navigator.share({ title, text, url: shareUrl });
        return;
      } catch (e) {
        // User cancelled or share failed — fall through to clipboard
        if (e instanceof Error && e.name === "AbortError") return;
      }
    }

    // Fallback: copy to clipboard
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Last resort: prompt
      window.prompt("링크를 복사하세요:", shareUrl);
    }
  }, [title, text, url]);

  return (
    <button
      type="button"
      onClick={handleShare}
      className={`inline-flex items-center gap-1.5 rounded-lg border px-3 py-2 text-sm font-medium transition-colors hover:bg-gray-50 ${className ?? ""}`}
      style={copied ? { borderColor: accentColor, color: accentColor } : undefined}
      aria-label={copied ? "링크 복사됨" : "공유하기"}
    >
      {copied ? (
        <>
          <CheckIcon />
          링크 복사됨
        </>
      ) : (
        <>
          <ShareIcon />
          공유하기
        </>
      )}
    </button>
  );
}

function ShareIcon() {
  return (
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
      <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />
      <polyline points="16 6 12 2 8 6" />
      <line x1="12" x2="12" y1="2" y2="15" />
    </svg>
  );
}

function CheckIcon() {
  return (
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
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
