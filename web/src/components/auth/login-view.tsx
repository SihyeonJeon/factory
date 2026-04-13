"use client";

import { useCallback, useState } from "react";
import { signInWithKakao, signInWithApple } from "@/lib/auth";
import { useKakaoBrowser } from "@/hooks/use-kakao-browser";
import { KakaoLoginGate } from "@/components/kakao/kakao-login-gate";
import { Button } from "@/components/ui/button";

interface LoginViewProps {
  error?: string;
  redirectTo?: string;
}

const ERROR_MESSAGES: Record<string, string> = {
  no_code: "로그인이 취소되었어요. 다시 시도해주세요.",
  auth_exchange_failed: "인증에 실패했어요. 다시 시도해주세요.",
};

export function LoginView({ error, redirectTo }: LoginViewProps) {
  const [loading, setLoading] = useState<"kakao" | "apple" | null>(null);
  const [consent, setConsent] = useState(false);
  const { isKakao } = useKakaoBrowser();

  const handleKakaoLogin = useCallback(async () => {
    setLoading("kakao");
    const { error: authError } = await signInWithKakao(redirectTo);
    if (authError) {
      setLoading(null);
    }
    // On success, the browser redirects to Kakao OAuth — no need to reset loading
  }, [redirectTo]);

  const handleAppleLogin = useCallback(async () => {
    setLoading("apple");
    const { error: authError } = await signInWithApple(redirectTo);
    if (authError) {
      setLoading(null);
    }
  }, [redirectTo]);

  const errorMessage = error ? ERROR_MESSAGES[error] ?? "로그인 중 문제가 발생했어요." : null;

  return (
    <main className="flex min-h-dvh flex-col items-center justify-center px-6">
      <div className="w-full max-w-sm space-y-8">
        {/* Brand */}
        <div className="text-center space-y-2">
          <h1 className="text-3xl font-bold tracking-tight">모먼트</h1>
          <p className="text-sm text-muted-foreground">
            프라이빗 모임을 더 쉽게
          </p>
        </div>

        {/* Error message */}
        {errorMessage && (
          <div className="rounded-xl border border-destructive/20 bg-destructive/5 px-4 py-3 text-center text-sm text-destructive">
            {errorMessage}
          </div>
        )}

        {/* Privacy consent */}
        <label className="flex items-start gap-3 cursor-pointer">
          <input
            type="checkbox"
            checked={consent}
            onChange={(e) => setConsent(e.target.checked)}
            className="mt-0.5 h-5 w-5 rounded border-gray-300 accent-[#FF6B9D] shrink-0"
          />
          <span className="text-xs text-muted-foreground leading-relaxed">
            <a href="/terms" target="_blank" rel="noopener noreferrer" className="underline underline-offset-2 hover:text-foreground">서비스 이용약관</a>
            {" "}및{" "}
            <a href="/privacy" target="_blank" rel="noopener noreferrer" className="underline underline-offset-2 hover:text-foreground">개인정보처리방침</a>
            에 동의합니다. (필수)
          </span>
        </label>

        {/* Login buttons */}
        <div className="space-y-3">
          <KakaoLoginGate loginUrl={`/login?next=${encodeURIComponent(redirectTo ?? "/")}`}>
            <Button
              onClick={handleKakaoLogin}
              disabled={loading !== null || !consent}
              className="h-12 w-full rounded-xl text-sm font-semibold"
              style={{
                backgroundColor: "#FEE500",
                color: "#191919",
              }}
            >
              {loading === "kakao" ? (
                <span className="animate-pulse">로그인 중...</span>
              ) : (
                <>
                  <KakaoIcon />
                  <span className="ml-2">카카오로 시작하기</span>
                </>
              )}
            </Button>
          </KakaoLoginGate>

          {/* Apple login — shown as fallback, or when user prefers Apple */}
          {!isKakao && (
            <Button
              onClick={handleAppleLogin}
              disabled={loading !== null || !consent}
              variant="outline"
              className="h-12 w-full rounded-xl text-sm font-semibold border-2"
              style={{
                backgroundColor: "#000000",
                color: "#FFFFFF",
                borderColor: "#000000",
              }}
            >
              {loading === "apple" ? (
                <span className="animate-pulse">로그인 중...</span>
              ) : (
                <>
                  <AppleIcon />
                  <span className="ml-2">Apple로 시작하기</span>
                </>
              )}
            </Button>
          )}
        </div>

      </div>
    </main>
  );
}

/** Kakao speech bubble icon (simplified SVG) */
function KakaoIcon() {
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 18 18"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M9 0.6C4.03 0.6 0 3.713 0 7.55c0 2.486 1.657 4.67 4.148 5.897l-1.059 3.88c-.094.343.3.614.593.407l4.637-3.06A12.3 12.3 0 0 0 9 14.5c4.97 0 9-3.113 9-6.95S13.97.6 9 .6"
        fill="#191919"
      />
    </svg>
  );
}

/** Apple logo icon (simplified SVG) */
function AppleIcon() {
  return (
    <svg
      width="16"
      height="18"
      viewBox="0 0 16 20"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      <path d="M13.182 10.546c-.02-2.065 1.662-3.078 1.74-3.127-0.953-1.404-2.43-1.594-2.949-1.609-1.243-.133-2.451.748-3.084.748-.647 0-1.621-.735-2.674-.714-1.358.02-2.633.81-3.328 2.035-1.44 2.52-.367 6.222 1.014 8.262.694 1.003 1.507 2.12 2.568 2.082 1.04-.042 1.428-.672 2.683-.672 1.243 0 1.607.672 2.688.648 1.112-.019 1.81-.1 2.49-1.112.8-1.167 1.124-2.316 1.138-2.374-.025-.01-2.17-.843-2.19-3.355h-.096zm-2.052-6.157c.556-.695.937-1.636.833-2.589-.808.035-1.818.56-2.397 1.24-.513.603-.974 1.594-.855 2.527.909.07 1.841-.465 2.419-1.178z" />
    </svg>
  );
}
