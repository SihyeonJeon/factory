# Blackboard - Agent Shared Context

---
**[2026-04-12 harness-reset]** Harness transformed from iOS/Unfading couple memory app to Moment (모먼트) web platform. Architecture: Planner-Generator-Evaluator (3-agent). Stack: Next.js 15 + PWA + Supabase + Vercel. iOS roles removed, web roles active.

---
**[2026-04-12 18:46:12]** `product_research` via `product_lead:claude-opus-4-6`
{"summary": "모먼트(Moment)는 한국 2030세대 반복 개최자를 위한 프라이빗 모임 운영 플랫폼으로, Partiful 모델을 카카오 생태계에 최적화한 한국향 이벤트 RSVP + 운영 자동화 서비스다. 핵심 가치는 (1) 60초 이벤트 페이지 생성 + 카카오톡 OG 공유, (2) 앱 설치 없는 PWA RSVP, (3) 참석 대시보드 + 정산 자동화이며, '지인 기반 프라이빗 모임 전용 RSVP + 관계 인텔리전스'를 통합한 한국 서비스가 부재한 시장 공백을 공략한다. MVP 8주 스코프는 5개 에픽(이벤트 생성, RSV

---
**[2026-04-12 18:49:02]** `planning` via `delivery_lead:claude-sonnet-4-6`
{"execution_summary": "모먼트 MVP 8주 스프린트: 3개 병렬 레인(frontend/backend/qa)으로 5개 에픽을 2주 단위 4스프린트로 분해. W1-2 파운데이션(스키마+RLS+PWA 스캐폴드+카카오 OAuth), W3-4 이벤트 생성+RSVP(60초 생성·OG 카드·카카오톡 인앱 브라우저 호환), W5-6 대시보드+사진(Realtime·FCM 리마인더·스토리지 타임라인), W7-8 정산+릴리즈 게이트(토스·카카오페이 딥링크·Lighthouse·RLS 감사). 핵심 기술 리스크: iOS 카카오톡 WebV

---
**[2026-04-12 19:18:19]** `architecture` via `product_lead:claude-opus-4-6`
The plan is ready for your review. Here's a summary of what was designed:

**Moment MVP 8-week execution plan** covering:
- **4 sprints** × 3 parallel lanes (backend/frontend/qa) with explicit merge ordering
- **50+ granular tasks** with dependency chains (B1.1→B1.12, F1.1→F1.14, etc.)
- **6 Supabas

---
**[2026-04-12 19:25:53]** `web_implementation` via `web_builder:claude-opus-4-6`
I'll wait for your answer on project root location before finalizing the plan.

---
**[2026-04-12 19:32:24]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: 이벤트 생성 위저드 UI

### Changed / Created Files

| File | Purpose |
|------|---------|
| `web/` | Next.js 16 project scaffold (App Router, TypeScript strict, Tailwind 4, shadcn/ui) |
| `src/app/layout.tsx` | Root layout — Noto Sans KR font, `lang="ko"`, PWA manifest link, v

---
**[2026-04-12 19:36:33]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: 게스트 RSVP 플로우

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/types.ts` | `RsvpStatus`, `GuestRsvp`, `RSVP_STATUS_CONFIG`, `EventDetail` 타입 추가 |
| `src/lib/mock-event.ts` | 백엔드 대기 중 프론트엔드 개발용 목 이벤트 데이터 |
| `src/app/event/[id]/page.tsx` | S

---
**[2026-04-12 19:40:39]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: 호스트 대시보드 Realtime UI

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/types.ts` | `GuestResponseStatus`, `DashboardGuest`, `AttendanceCounts` 타입 추가 |
| `src/lib/mock-dashboard.ts` | 8명 목 게스트 데이터 + `calcAttendanceCounts` 유틸리티 |
| `src/hooks

---
**[2026-04-12 19:46:16]** `web_implementation` via `web_builder:claude-opus-4-6`
Build passes. All routes are registered including `/event/[id]/photos`.

---

## Implementation Report: 사진 타임라인 + 스와이프 뷰어

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/types.ts` | `TimelinePhoto` 인터페이스 추가 (id, url, thumbnailUrl, uploader, dimensions) |
| `src/lib/moc

---
**[2026-04-12 19:51:30]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: 모바일 퍼스트 반응형 레이아웃 (375/768/1280px)

### Changed Files

| File | Purpose |
|------|---------|
| `src/app/globals.css` | PWA safe-area inset utilities (`safe-top`/`safe-bottom`), 44px minimum touch target on `pointer: coarse` devices, `scrollbar-none` utility, smooth scro

---
**[2026-04-12 19:54:22]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: PWA Service Worker + Install Prompt

### Changed / Created Files

| File | Purpose |
|------|---------|
| `public/sw.js` | Service worker — cache-first for static assets, network-first for API routes, stale-while-revalidate for HTML pages. Versioned cache (`moment-v1`)

---
**[2026-04-12 19:57:45]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: 카카오톡 인앱 브라우저 UX 핸들링

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/kakao-browser.ts` | KakaoTalk in-app browser detection (`detectKakaoBrowser`) + external browser URL builder (`getExternalBrowserUrl`) for iOS `kakaotalk://web/openExtern

---
**[2026-04-12 20:03:54]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: Supabase 스키마 마이그레이션 + RLS 정책 전체

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/migrations/00001_initial_schema.sql` | 6개 테이블 DDL — `profiles`, `events`, `guest_states`, `media_timeline`, `settlements`, `reminders`. 3개 enum (`event_mood`

---
**[2026-04-12 20:09:25]** `web_implementation` via `web_builder:claude-opus-4-6`
---

## Implementation Report: 카카오 OAuth Supabase Auth 연동 (Apple 폴백)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/auth.ts` | Auth helper functions — `signInWithKakao()`, `signInWithApple()`, `signOut()`, `getCurrentUser()`. Builds OAuth redirect URL dynamically for 

---
**[2026-04-12 20:12:59]** `web_implementation` via `web_builder:claude-opus-4-6`
Build passes, implementation is complete. Here's the implementation report:

---

## Implementation Report: Supabase Realtime 구독 (guest_states)

### Changed Files

| File | Purpose |
|------|---------|
| `src/hooks/use-realtime-guests.ts` | Replaced mock data with real Supabase Realtime subscription

---
**[2026-04-12 20:18:24]** `web_implementation` via `web_builder:claude-opus-4-6`
Build passes, TypeScript compiles cleanly. Here's the implementation report:

---

## Implementation Report: FCM 연동 + send-reminder Edge Function (D-1 cron)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/migrations/00004_fcm_tokens.sql` | Adds `fcm_token` and `fcm_to

---
**[2026-04-12 20:23:33]** `web_implementation` via `web_builder:claude-opus-4-6`
Build passes, TypeScript compiles cleanly. Here's the implementation report:

---

## Implementation Report: Supabase Storage 정책 + media_timeline 업로드 파이프라인

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/migrations/00005_storage_policies.sql` | Creates `event-media` S

---
**[2026-04-12 20:25:39]** `web_implementation` via `web_builder:claude-opus-4-6`
Build passes, implementation is complete. Here's the implementation report:

---

## Implementation Report: settlement-calc Edge Function (1/N + 딥링크)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/functions/settlement-calc/index.ts` | Edge Function — 1/N settlement c

---
**[2026-04-12 20:29:44]** `web_implementation` via `web_builder:claude-opus-4-6`
Build passes, TypeScript compiles cleanly. Here's the implementation report:

---

## Implementation Report: og-image Edge Function (Satori fallback)

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/app/event/[id]/opengraph-image.tsx` | **Primary** OG image generator using 

---
**[2026-04-12 22:40:45]** `code_review` via `delivery_lead:claude-opus-4-6`
리뷰가 완료되었습니다. **BLOCK RELEASE** — Critical 3건(mock 데이터 사용, 정산 인가 누락, 리마인더 인가 누락)과 High 5건(공개 RLS, 확장자 미검증, open redirect, state 미검증, 터치 타겟 미달)이 해결될 때까지 릴리스를 차단합니다.

Generator에게 돌려보낼 수정 우선순위:
1. **C-1 → C-2 → C-3** (기능 정합성 + 보안 — 가장 시급)
2. **H-5** (접근성 릴리스 차단 기준)
3. **H-1 → H-3** (보안)
4. **M-1** (카카오톡
