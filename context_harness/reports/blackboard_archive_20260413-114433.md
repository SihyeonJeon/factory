# Blackboard - Agent Shared Context

# Blackboard Compact

## Recent entries
- ## Implementation Report: FCM 연동 + send-reminder Edge Function (D-1 cron)
- **[2026-04-12 20:23:33]** `web_implementation` via `web_builder:claude-opus-4-6`
- ## Implementation Report: Supabase Storage 정책 + media_timeline 업로드 파이프라인
- **[2026-04-12 20:25:39]** `web_implementation` via `web_builder:claude-opus-4-6`
- ## Implementation Report: settlement-calc Edge Function (1/N + 딥링크)
- **[2026-04-12 20:29:44]** `web_implementation` via `web_builder:claude-opus-4-6`
- ## Implementation Report: og-image Edge Function (Satori fallback)
- **[2026-04-12 22:40:45]** `code_review` via `delivery_lead:claude-opus-4-6`

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
