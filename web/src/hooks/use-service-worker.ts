"use client";

import { useEffect, useRef } from "react";
import { detectKakaoBrowser } from "@/lib/kakao-browser";

export function useServiceWorker() {
  const registered = useRef(false);

  useEffect(() => {
    if (registered.current) return;
    if (typeof window === "undefined" || !("serviceWorker" in navigator)) return;

    // Skip SW registration in KakaoTalk in-app browser — it has limited
    // WebView support and SW registration can silently fail or cause issues
    // with navigation and OAuth redirects.
    const { isKakao } = detectKakaoBrowser();
    if (isKakao) return;

    registered.current = true;

    navigator.serviceWorker
      .register("/sw.js", { scope: "/" })
      .then((reg) => {
        reg.addEventListener("updatefound", () => {
          const newWorker = reg.installing;
          if (!newWorker) return;

          newWorker.addEventListener("statechange", () => {
            if (
              newWorker.state === "activated" &&
              navigator.serviceWorker.controller
            ) {
              // New version available — could show update toast here
            }
          });
        });
      })
      .catch((err) => {
        console.warn("SW registration failed:", err);
      });
  }, []);
}
