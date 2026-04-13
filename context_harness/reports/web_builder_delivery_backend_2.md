---

## Implementation Report: 카카오 OAuth Supabase Auth 연동 (Apple 폴백)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/auth.ts` | Auth helper functions — `signInWithKakao()`, `signInWithApple()`, `signOut()`, `getCurrentUser()`. Builds OAuth redirect URL dynamically for dev/prod. Kakao scopes: `profile_nickname profile_image account_email`. |
| `src/app/auth/callback/route.ts` | Route handler at `/auth/callback` — exchanges Supabase OAuth `code` for session, sets auth cookies, redirects to `?next=` param or `/`. Handles errors by redirecting to `/login?error=`. |
| `supabase/migrations/00003_auth_profile_sync.sql` | Two PostgreSQL triggers on `auth.users`: `on_auth_user_created` (INSERT) and `on_auth_user_updated` (UPDATE of `raw_user_meta_data`). Extracts `kakao_id`, `display_name`, `avatar_url` from OAuth metadata and upserts into `public.profiles`. Handles Kakao, Apple, and generic providers. |
| `src/hooks/use-auth.ts` | Client-side React hook — subscribes to `onAuthStateChange`, exposes `{ user, loading, isAuthenticated, signOut }`. |
| `src/app/login/page.tsx` | Login page with SSR metadata. Passes `?error` and `?next` search params to `LoginView`. |
| `src/components/auth/login-view.tsx` | Login UI — Kakao (yellow #FEE500) + Apple (black) login buttons. Integrates `KakaoLoginGate` to handle in-app browser restrictions. Displays Korean error messages. Terms notice placeholder. |
| `src/middleware.ts` | **Updated** — added auth guard for `/create` and `/dashboard` routes. Unauthenticated users are redirected to `/login?next=<path>`. Public routes (`/event/[id]`, `/login`, `/`) remain open. |

### Architecture Decisions

- **Supabase Auth native OAuth** — no custom token handling. Kakao and Apple providers configured via Supabase Dashboard.
- **PKCE flow** via `@supabase/ssr` — auth code exchange happens server-side in the callback route, session stored in httpOnly cookies.
- **Profile sync via DB triggers** (not application code) — guarantees a `profiles` row exists for every authenticated user regardless of which code path created them.
- **KakaoTalk in-app browser** — existing `KakaoLoginGate` component gates the Kakao login button; iOS users are redirected to external browser to avoid session isolation.

### Remaining Dependencies for Next Subtask

- **Supabase Dashboard config required**: Enable Kakao + Apple providers, set client IDs/secrets, add callback URL.
- **Environment variables**: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SITE_URL` (production).
- **Next.js 16 deprecation**: `middleware.ts` convention is deprecated in favor of `proxy.ts` — functional but should be migrated in a later sprint.
- **Build status**: `next build` passes with 0 TypeScript errors. `/login` route renders at build time, `/auth/callback` is dynamic.
