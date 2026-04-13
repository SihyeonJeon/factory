"use client";

import { useCallback, useEffect, useRef, useState } from "react";

interface BeforeInstallPromptEvent extends Event {
  readonly platforms: string[];
  prompt(): Promise<{ outcome: "accepted" | "dismissed" }>;
}

export function useInstallPrompt() {
  const [canInstall, setCanInstall] = useState(false);
  const deferredPrompt = useRef<BeforeInstallPromptEvent | null>(null);

  useEffect(() => {
    // Don't show if already installed (standalone mode)
    if (window.matchMedia("(display-mode: standalone)").matches) return;

    // Don't show if user dismissed within last 7 days
    const dismissed = localStorage.getItem("moment-install-dismissed");
    if (dismissed && Date.now() - Number(dismissed) < 7 * 24 * 60 * 60 * 1000) return;

    const handler = (e: Event) => {
      e.preventDefault();
      deferredPrompt.current = e as BeforeInstallPromptEvent;
      setCanInstall(true);
    };

    window.addEventListener("beforeinstallprompt", handler);
    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  const install = useCallback(async () => {
    const prompt = deferredPrompt.current;
    if (!prompt) return false;

    const { outcome } = await prompt.prompt();
    deferredPrompt.current = null;
    setCanInstall(false);

    return outcome === "accepted";
  }, []);

  const dismiss = useCallback(() => {
    localStorage.setItem("moment-install-dismissed", String(Date.now()));
    deferredPrompt.current = null;
    setCanInstall(false);
  }, []);

  return { canInstall, install, dismiss };
}
