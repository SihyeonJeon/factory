---

## Implementation Report: PWA Service Worker + Install Prompt

### Changed / Created Files

| File | Purpose |
|------|---------|
| `public/sw.js` | Service worker — cache-first for static assets, network-first for API routes, stale-while-revalidate for HTML pages. Versioned cache (`moment-v1`) with old-cache cleanup on activate. |
| `public/icons/icon-192.svg` | 192x192 SVG placeholder icon (pink `M` logo on #FF6B9D background) |
| `public/icons/icon-512.svg` | 512x512 SVG placeholder icon (maskable) |
| `public/manifest.json` | Updated icon references from PNG→SVG, added `id` and `scope` fields |
| `src/hooks/use-service-worker.ts` | Client hook — registers `/sw.js`, listens for `updatefound` events |
| `src/hooks/use-install-prompt.ts` | Client hook — captures `beforeinstallprompt` event, provides `install()` and `dismiss()` with 7-day cooldown, skips if already in standalone mode |
| `src/components/pwa/install-prompt.tsx` | Bottom banner UI — "모먼트 앱 설치" with install/dismiss buttons, `animate-in slide-in-from-bottom` transition |
| `src/components/pwa/pwa-provider.tsx` | Client wrapper combining SW registration + install prompt |
| `src/app/layout.tsx` | Added `<PwaProvider />` to root layout body |

### Caching Strategy

- **Static assets** (`/_next/static/`, `/icons/`, `/covers/`): Cache-first — fast loads from cache, fallback to network
- **API / data routes** (`/api/`, `/_next/data/`): Network-first — fresh data, cache fallback for offline
- **HTML pages**: Stale-while-revalidate — instant cached response, background refresh

### Remaining Dependencies

- **Production icons**: SVG placeholders work for development and modern browsers. For production, convert to PNG (192x192 + 512x512) for broader compatibility (older Android, Safari).
- **카카오톡 인앱 브라우저 UX 핸들링** (next subtask): The install prompt already detects standalone mode and skips — KakaoTalk WebView handling will need separate detection logic in the next subtask.
