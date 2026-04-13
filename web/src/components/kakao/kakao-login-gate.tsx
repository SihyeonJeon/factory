"use client";

import { useCallback } from "react";
import { useKakaoBrowser } from "@/hooks/use-kakao-browser";
import { getExternalBrowserUrl } from "@/lib/kakao-browser";
import { Button } from "@/components/ui/button";

interface KakaoLoginGateProps {
  /** The URL to redirect to for login (e.g. /api/auth/kakao) */
  loginUrl: string;
  /** Children rendered when login is possible (not blocked by in-app browser) */
  children: React.ReactNode;
  /** Optional: override display when blocked in KakaoTalk WebView */
  fallback?: React.ReactNode;
}

/**
 * Gate component that prevents OAuth login attempts inside KakaoTalk in-app browser.
 *
 * KakaoTalk iOS WebView has session isolation — after OAuth redirect back,
 * the session cookie may not persist, causing login to silently fail.
 * Instead, we guide the user to open the page in their default browser first.
 */
export function KakaoLoginGate({
  loginUrl,
  children,
  fallback,
}: KakaoLoginGateProps) {
  const { isKakao, isKakaoIOS } = useKakaoBrowser();

  const handleOpenExternal = useCallback(() => {
    // Build the OAuth login URL relative to the current origin
    const absoluteLoginUrl = new URL(loginUrl, window.location.origin).href;
    const url = getExternalBrowserUrl(absoluteLoginUrl, isKakaoIOS);
    window.location.href = url;
  }, [loginUrl, isKakaoIOS]);

  if (!isKakao) return <>{children}</>;

  if (fallback) return <>{fallback}</>;

  return (
    <div className="flex flex-col items-center gap-4 rounded-2xl border bg-card p-6 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
        <span className="text-xl">🔐</span>
      </div>
      <div className="space-y-1">
        <p className="text-sm font-semibold">로그인이 필요해요</p>
        <p className="text-xs text-muted-foreground leading-relaxed">
          카카오톡 내부에서는 로그인이 제한될 수 있어요.
          <br />
          기본 브라우저에서 열면 바로 로그인할 수 있어요.
        </p>
      </div>
      <Button
        onClick={handleOpenExternal}
        className="h-11 w-full rounded-xl text-sm font-semibold"
      >
        브라우저에서 로그인하기
      </Button>
    </div>
  );
}
