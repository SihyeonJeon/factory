/**
 * KakaoTalk in-app browser detection and utilities.
 *
 * KakaoTalk's in-app browser is a WebView with known limitations:
 * - iOS: WKWebView (Safari-based) with cookie/session isolation
 * - Android: Chromium-based WebView
 * - No PWA install prompt (beforeinstallprompt never fires)
 * - Service worker registration may silently fail or be restricted
 * - OAuth redirects can break due to session isolation
 * - window.open may be blocked
 */

export interface KakaoBrowserInfo {
  /** Running inside KakaoTalk in-app browser */
  isKakao: boolean;
  /** Running inside any in-app browser (KakaoTalk, Naver, Instagram, etc.) */
  isInAppBrowser: boolean;
  /** iOS KakaoTalk WebView (most restrictive) */
  isKakaoIOS: boolean;
  /** Android KakaoTalk WebView */
  isKakaoAndroid: boolean;
}

/** UA substring present in KakaoTalk in-app browser */
const KAKAO_UA = /KAKAOTALK/i;
const NAVER_UA = /NAVER\(|SamsungBrowser.*NAVER/i;
const INSTAGRAM_UA = /Instagram/i;
const LINE_UA = /Line\//i;
const FACEBOOK_UA = /FBAN|FBAV/i;

/**
 * Detect whether the current browser is KakaoTalk or another in-app browser.
 * Safe to call on the server (returns all false).
 */
export function detectKakaoBrowser(
  ua?: string
): KakaoBrowserInfo {
  const userAgent =
    ua ?? (typeof navigator !== "undefined" ? navigator.userAgent : "");

  const isKakao = KAKAO_UA.test(userAgent);
  const isIOS = /iPhone|iPad|iPod/i.test(userAgent);

  const isInAppBrowser =
    isKakao ||
    NAVER_UA.test(userAgent) ||
    INSTAGRAM_UA.test(userAgent) ||
    LINE_UA.test(userAgent) ||
    FACEBOOK_UA.test(userAgent);

  return {
    isKakao,
    isInAppBrowser,
    isKakaoIOS: isKakao && isIOS,
    isKakaoAndroid: isKakao && !isIOS,
  };
}

/**
 * Build a URL intent to open the current page in the device's default browser.
 * - Android: intent:// scheme for Chrome
 * - iOS: Safari universal link trick (KakaoTalk supports `kakaotalk://web/openExternal`)
 * Falls back to returning the URL as-is if neither platform is detected.
 */
export function getExternalBrowserUrl(targetUrl: string, isIOS: boolean): string {
  if (isIOS) {
    // KakaoTalk iOS supports the kakaotalk://web/openExternal?url= scheme
    return `kakaotalk://web/openExternal?url=${encodeURIComponent(targetUrl)}`;
  }

  // Android: intent scheme opens in the default browser
  const url = new URL(targetUrl);
  return `intent://${url.host}${url.pathname}${url.search}${url.hash}#Intent;scheme=${url.protocol.replace(":", "")};package=com.android.chrome;end`;
}
