Build passes, TypeScript compiles cleanly. Here's the implementation report:

---

## Implementation Report: FCM 연동 + send-reminder Edge Function (D-1 cron)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/migrations/00004_fcm_tokens.sql` | Adds `fcm_token` and `fcm_token_updated_at` columns to `profiles` table with partial index |
| `supabase/functions/send-reminder/index.ts` | Supabase Edge Function — D-1 cron finds events in 23-25h window, sends FCM v1 API push to attending guests + host, logs to `reminders` table. Also supports manual POST with `{ event_id }` |
| `src/lib/fcm.ts` | Client-side Firebase Messaging — lazy init, `registerFCMToken()` (permission + token + Supabase save), `onForegroundMessage()` listener |
| `src/hooks/use-fcm.ts` | React hook wrapping FCM registration + foreground notification state |
| `src/app/api/fcm-token/route.ts` | `POST /api/fcm-token` — saves FCM token to authenticated user's profile |
| `src/app/api/reminders/send/route.ts` | `POST /api/reminders/send` — host-only manual reminder trigger, delegates to Edge Function |
| `public/firebase-messaging-sw.js` | Firebase Messaging service worker for background push notifications + notification click handling |
| `src/lib/database.types.ts` | Updated — added `fcm_token`/`fcm_token_updated_at` to profiles, added `Relationships` arrays to all tables (fixes pre-existing `never` type issue) |
| `tsconfig.json` | Excludes `supabase/functions` from TypeScript compilation (Deno runtime) |
| `package.json` | Added `firebase` dependency |

### Architecture

- **D-1 cron**: Edge Function scheduled at `0 9 * * *` (09:00 KST) via Supabase Dashboard. Queries events in 23-25h window, skips already-sent d1 reminders, sends FCM v1 API multicast.
- **Manual trigger**: Host calls `POST /api/reminders/send` → verifies ownership → invokes Edge Function with service role key → logs as `manual` type.
- **FCM auth**: Edge Function uses Google service account JWT → OAuth2 token → FCM v1 HTTP API (no Firebase Admin SDK needed in Deno).
- **Client flow**: `useFCM(isAuthenticated)` → permission request → `getToken()` → saves to `profiles.fcm_token`.

### Required Environment Variables

| Variable | Where | Purpose |
|----------|-------|---------|
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Next.js | Firebase client config |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Next.js | Firebase client config |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | Next.js | Firebase client config |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | Next.js | Firebase client config |
| `NEXT_PUBLIC_FIREBASE_VAPID_KEY` | Next.js | FCM web push VAPID key |
| `SUPABASE_SERVICE_ROLE_KEY` | Next.js server | Edge Function invocation auth |
| `FCM_PROJECT_ID` | Edge Function secret | FCM v1 API project |
| `FCM_CLIENT_EMAIL` | Edge Function secret | Service account email |
| `FCM_PRIVATE_KEY` | Edge Function secret | Service account private key |
| `SITE_URL` | Edge Function secret | Push notification click URL base |

### Remaining Dependencies for Next Subtask

- Supabase Dashboard: enable cron schedule `0 9 * * *` for `send-reminder` function
- Firebase Console: create web app, generate VAPID key pair
- `firebase-messaging-sw.js` needs Firebase config injected at deploy time (currently uses `self.__FIREBASE_CONFIG__`)
