"use client";

import { useState, useCallback } from "react";
import { useKakaoBrowser } from "@/hooks/use-kakao-browser";
import { getExternalBrowserUrl } from "@/lib/kakao-browser";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";

/**
 * Banner shown inside KakaoTalk in-app browser that guides users
 * to open the page in their default browser for full functionality.
 *
 * Reasons to leave the in-app browser:
 * - OAuth redirects may fail due to cookie isolation
 * - PWA install is not available
 * - Camera/file APIs can be restricted
 */
export function ExternalBrowserBanner() {
  const { isKakao, isKakaoIOS } = useKakaoBrowser();
  const [dismissed, setDismissed] = useState(false);

  const handleOpen = useCallback(() => {
    const url = getExternalBrowserUrl(window.location.href, isKakaoIOS);
    window.location.href = url;
  }, [isKakaoIOS]);

  if (!isKakao || dismissed) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-50 safe-top">
      <div className="mx-auto max-w-lg border-b bg-amber-50 px-4 py-3">
        <div className="flex items-start gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium text-amber-900">
              카카오톡 인앱 브라우저에서 열렸어요
            </p>
            <p className="mt-0.5 text-xs text-amber-700">
              로그인 및 사진 업로드를 위해 기본 브라우저에서 열어주세요
            </p>
          </div>
          <div className="flex shrink-0 items-center gap-1">
            <Button
              size="sm"
              variant="outline"
              onClick={handleOpen}
              className="h-8 rounded-lg border-amber-300 bg-white px-3 text-xs font-medium text-amber-900 hover:bg-amber-100"
            >
              브라우저로 열기
            </Button>
            <button
              onClick={() => setDismissed(true)}
              className="flex h-8 w-8 items-center justify-center rounded-full text-amber-600 hover:bg-amber-100 transition-colors"
              aria-label="닫기"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
