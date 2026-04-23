---
round: round_calendar_plans_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-calendar-plans
contract_hash: none
created_at: 2026-04-23T17:40:00Z
codex_session_id: capacity_failed_operator_fallback
---
# R26 Calendar plans + monthly expense + KST — plan & outcome

## Context
F9 (월 지출), F2-cal (미래=계획 / 과거=추억, 알람), F2 (KST).

## Decision
Codex capacity 3회 실패 → operator fallback. claude_code 가 직접 구현.

## Challenge Section
### Risk
- MemoryCalendarStore memory dots 이 여전히 SampleMemoryPin 기반 sample 데이터. 실제 MemoryStore 와 동기화는 C1 에서 같이. 이번 라운드는 "미래는 추억 점 표시 억제" 만 해결.
- 알람 권한 거부 graceful: 이벤트는 저장되고 배너만 표시.

## Outcome
- KSTDateFormatter (timeZone+locale 고정)
- EventRepository + SupabaseEventRepository
- DBEvent
- MemoryCalendarStore.loadMonth(for:)
- CalendarView: 월 지출 헤더 + 미래 날짜 EventPlanSheet 트리거 + 과거 memory list
- MonthlyExpenseHeader / EventPlanSheet views
- UnfadingLocalized.Calendar 14 keys
- KSTDateFormatterTests 5 cases (midnight boundary 포함)

## Verification
- Operator 가 통합 xcodebuild test.
