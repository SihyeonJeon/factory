---

## Implementation Report: 카카오톡 인앱 브라우저 UX 핸들링

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/kakao-browser.ts` | KakaoTalk in-app browser detection (`detectKakaoBrowser`) + external browser URL builder (`getExternalBrowserUrl`) for iOS `kakaotalk://web/openExternal` and Android intent scheme |
| `src/hooks/use-kakao-browser.ts` | Client-side hook wrapping `detectKakaoBrowser`, SSR-safe (returns all-false during SSR to avoid hydration mismatch) |
| `src/components/kakao/external-browser-banner.tsx` | Dismissible top banner shown inside KakaoTalk WebView, guides users to open in default browser for OAuth/photo upload compatibility |
| `src/components/kakao/kakao-login-gate.tsx` | Gate component that blocks OAuth login attempts in KakaoTalk WebView and redirects to external browser instead (prevents session isolation failures on iOS) |
| `src/hooks/use-service-worker.ts` | **Modified** — skips SW registration inside KakaoTalk in-app browser to avoid silent failures and OAuth redirect interference |
| `src/app/layout.tsx` | **Modified** — integrated `ExternalBrowserBanner` at body top (renders globally, self-hides when not in KakaoTalk) |
| `src/app/globals.css` | **Modified** — added `.kakao-banner-offset` utility for scroll-padding when banner is visible |

### Key Design Decisions

1. **Detection covers all major Korean in-app browsers** (KakaoTalk, Naver, Instagram, LINE, Facebook) via `isInAppBrowser` flag, but KakaoTalk-specific behavior only triggers on `isKakao`.

2. **External browser redirect uses platform-specific schemes**: iOS uses `kakaotalk://web/openExternal?url=`, Android uses `intent://` Chrome scheme. Both are KakaoTalk-documented mechanisms.

3. **Service worker is disabled in KakaoTalk** — the WebView's restricted SW support can interfere with OAuth redirect flows and cache behavior. Pages still work fine without SW (network-only).

4. **`KakaoLoginGate` is a reusable component** for future OAuth integration — backend lane can wrap the Kakao login button with it to prevent broken login flows.

### Remaining Dependencies

- **Backend lane**: `KakaoLoginGate` needs the actual OAuth login URL (e.g. `/api/auth/kakao`) once Supabase Auth + Kakao OAuth is wired up.
- **QA lane**: iOS/Android KakaoTalk real-device testing to verify `kakaotalk://web/openExternal` and intent scheme work correctly across KakaoTalk versions.
