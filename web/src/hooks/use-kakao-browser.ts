"use client";

import { useState, useEffect } from "react";
import { detectKakaoBrowser, type KakaoBrowserInfo } from "@/lib/kakao-browser";

const DEFAULT_INFO: KakaoBrowserInfo = {
  isKakao: false,
  isInAppBrowser: false,
  isKakaoIOS: false,
  isKakaoAndroid: false,
};

/**
 * Hook that detects KakaoTalk in-app browser on the client side.
 * Returns all false during SSR to avoid hydration mismatch.
 */
export function useKakaoBrowser(): KakaoBrowserInfo {
  const [info, setInfo] = useState<KakaoBrowserInfo>(DEFAULT_INFO);

  useEffect(() => {
    setInfo(detectKakaoBrowser());
  }, []);

  return info;
}
