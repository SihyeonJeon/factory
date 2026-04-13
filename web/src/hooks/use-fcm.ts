"use client";

import { useEffect, useRef, useState } from "react";
import { registerFCMToken, onForegroundMessage } from "@/lib/fcm";

/**
 * Hook to register FCM token and listen for foreground messages.
 * Automatically requests permission and registers the token
 * when the user is authenticated.
 */
export function useFCM(isAuthenticated: boolean) {
  const [token, setToken] = useState<string | null>(null);
  const [notification, setNotification] = useState<{
    title?: string;
    body?: string;
    link?: string;
  } | null>(null);
  const registeredRef = useRef(false);

  useEffect(() => {
    if (!isAuthenticated || registeredRef.current) return;
    registeredRef.current = true;

    registerFCMToken().then((t) => {
      if (t) setToken(t);
    });
  }, [isAuthenticated]);

  useEffect(() => {
    if (!isAuthenticated) return;

    let unsubscribe: (() => void) | null = null;

    onForegroundMessage((payload) => {
      setNotification(payload);
      // Auto-clear after 5 seconds
      setTimeout(() => setNotification(null), 5000);
    }).then((unsub) => {
      unsubscribe = unsub;
    });

    return () => {
      unsubscribe?.();
    };
  }, [isAuthenticated]);

  return { token, notification, clearNotification: () => setNotification(null) };
}
