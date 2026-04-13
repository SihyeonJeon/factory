---

## Implementation Report: Supabase 스키마 마이그레이션 + RLS 정책 전체

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/migrations/00001_initial_schema.sql` | 6개 테이블 DDL — `profiles`, `events`, `guest_states`, `media_timeline`, `settlements`, `reminders`. 3개 enum (`event_mood`, `rsvp_status`, `fee_intention`, `reminder_type`). 인덱스 6개. `guest_states` Realtime publication. |
| `supabase/migrations/00002_rls_policies.sql` | 전 테이블 RLS 활성화 + 15개 정책. 프로필 공개 읽기/자기 수정, 이벤트 공개 읽기/호스트 CRUD, 게스트 상태 참여자 읽기/자기 RSVP, 미디어 참여자 읽기/참여자 업로드, 정산 호스트 관리/참여자 읽기, 리마인더 호스트 읽기(삽입은 Edge Function service_role). |
| `src/lib/database.types.ts` | `Database` 인터페이스 — 모든 테이블의 `Row`/`Insert`/`Update` 타입 + enum 타입 export. |
| `src/lib/supabase/client.ts` | 브라우저 Supabase 클라이언트 (`createBrowserClient<Database>`) |
| `src/lib/supabase/server.ts` | 서버 컴포넌트용 Supabase 클라이언트 (`createServerClient<Database>` + cookies) |
| `src/lib/supabase/middleware.ts` | 세션 갱신 미들웨어 (`updateSession`) |
| `src/middleware.ts` | Next.js 미들웨어 — Supabase 세션 자동 갱신 |
| `.env.local.example` | 환경변수 템플릿 (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`) |

### RLS Policy Summary

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | Public | Self only | Self only | — |
| `events` | Public (OG/SSR) | Auth (host_id=uid) | Host only | Host only |
| `guest_states` | Host + co-attendees | Self (user_id=uid) | Self only | Self only |
| `media_timeline` | Host + RSVPed guests | Participants only | — | Uploader only |
| `settlements` | Host + participants | Host only | Host only | — |
| `reminders` | Host only | service_role (Edge Fn) | — | — |

### Build Status

`next build` passes. All routes registered. TypeScript compilation clean.

### Dependencies for Next Subtask

- **카카오 OAuth 연동**: Supabase Dashboard에서 Kakao provider 활성화 필요 (`KAKAO_CLIENT_ID`, `KAKAO_CLIENT_SECRET`). `profiles` 테이블에 카카오 로그인 후 자동 프로필 생성 트리거 또는 클라이언트 사이드 upsert 로직 필요.
- **Supabase Storage**: `media_timeline` 업로드 파이프라인은 Storage bucket + Storage RLS 정책 별도 생성 필요.
- **Edge Functions**: `send-reminder`, `settlement-calc`, `og-image`는 `supabase/functions/` 디렉토리에 구현 예정.
