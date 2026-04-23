---
round: feedback_2026-04-23_s0_to_c2
stage: overall_planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-feedback-14items
contract_hash: none
created_at: 2026-04-23T16:45:00Z
codex_session_id: fresh_readonly
---
# 2026-04-23 사용자 피드백 14건 대응 — 스트림 플랜

## Context
사용자 실기기 테스트 중 14건 피드백 (docs/product-specs/user-feedback-2026-04-23.md). 권위 있는 디자인 소스: `docs/design-docs/Unfading Prototype.html`. 블로커 1건 (F12 RLS 재귀) + Prototype 충실도 + Composer 기능 회귀·확장.

## Decision
5개 라운드로 분할:
- **round_rls_and_feedback_schema_r1 (S0)** — backend only (claude_code 직접 SQL)
- **round_sheet_fidelity_r1 (A)** — F1/F2/F13/F14
- **round_composer_location_r1 (B)** — F3/F4/F5/F6/F7
- **round_calendar_plans_r1 (C2)** — F9/F2-cal + KST
- **round_composer_data_r1 (C1)** — F8/F10/F11 (B 완료 후 순차)

**병렬 실행 허용:** A ∥ B ∥ C2 (파일 화이트리스트 disjoint). C1은 B 직후.

## Challenge Section
### Objection (codex)
- Stage 7 parallel 은 disjoint 화이트리스트가 강제. A/B/C 원래 플랜은 composer/calendar/shared stores 가 중복 → 단순 "parallel" 선언은 위험. → 수용: 파일 단위로 분리하고 C를 C1+C2로 쪼갬.
- Stream C가 단일 dispatch로는 너무 큼. → 수용.

### Risk
- S0 schema/RLS 변경은 보안·정합성 측면 critical. Tester 계정으로 저장·조회 E2E 검증을 C 계열 dispatch 이전에 완료해야 함.
- F11 이벤트 모델: 범위 쿼리(`start_date <= T <= end_date`). 여행은 단일 row 로 저장. 1일 단위 중복 방지.
- F4 location permission: "현재 위치 사용" 경로에서만 요청하는 안 vs on-launch 요청 안. 사용자는 on-launch 명시 요청 → 수용.
- F12 fix는 `current_user_group_ids()` SECURITY DEFINER 헬퍼로 RLS 우회 subquery 제공. `stable sql`, `search_path` 고정, `authenticated` grant만.
- Missing points (codex): KST midnight boundary 테스트, 이벤트 overlap 처리, 알림권한 실패 UX, partial-insert rollback. 각 라운드 spec에 반영.

### Rejected alt
- `current_setting('jwt.claims.user_id')`-기반 RLS. 브랜드 JWT claim 포맷 의존. 유지·테스트성 떨어짐.
- Sheet drag `Animation.timingCurve(0.32, 0.72, 0, 1)` bezier 매칭 강제. iOS에서 velocity-aware spring 이 ergonomics 우수. Prototype 의 bezier 는 "시각 의도"로 취급하고 `.interpolatingSpring` 의 stiffness·damping 튜닝으로 시각 근접.

## 분할 화이트리스트 요약 (disjoint 검증)

| Stream | 핵심 파일 (예상) |
|---|---|
| S0 | Supabase migrations, `DBModels.swift` (+participant 컬럼, event reminder) |
| A | `MemoryMapHomeView.swift`, `UnfadingBottomSheet.swift`, `UnfadingFilterChip.swift`, `MemoryPinMarker.swift` |
| B | `MemoryComposerSheet.swift`, `MemoryComposerState.swift`, **새 `PlacePickerSheet.swift`**, `LocationPermissionStore.swift`, `App/MemoryMapApp.swift` (permission on-launch task) |
| C2 | `CalendarView.swift`, `MemoryCalendarStore.swift`, **새 `MonthlyExpenseHeader.swift`**, **새 `EventPlanSheet.swift`**, `UnfadingLocalized.swift` (Calendar namespace) |
| C1 (순차) | `MemoryComposerSheet.swift`, `MemoryComposerState.swift` (B 완료 후), **새 `ParticipantPickerChip.swift`**, **새 `EventScopeSheet.swift`**, `DBModels.swift` (DBMemory/Insert field expansion) |

A ∩ B = ∅ ✓
A ∩ C2 = ∅ ✓
B ∩ C2 = ∅ ✓ (UnfadingLocalized 섹션 다름)
B ∩ C1 = ⚠ (composer 공유) → 순차로 강제
A ∩ C1 = ∅ ✓
C1 ∩ C2 = ∅ ✓

## 실행 체크리스트
1. [claude_code] S0 migrations 적용 + tester 계정으로 저장 smoke
2. [claude_code] A, B, C2 parallel Codex dispatch (3개 동시)
3. [claude_code] B 완료 확인 후 C1 dispatch
4. 각 라운드 close: xcodebuild test + 실기기 smoke (사용자가 재실행)
