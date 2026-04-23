# round_calendar_plans_r1 — Calendar expense + future plans + KST (F9/F2-cal)

**Stage:** coding_1st
**Implementer:** claude_code (Codex capacity 차단으로 operator fallback)
**Scope:** F9 월 지출 헤더, F2-cal 미래=계획/과거=추억 구분, 알람 스케줄, KST 표시 일관.

## Acceptance
- `KSTDateFormatter` 공용 헬퍼 (timeZone Asia/Seoul + ko_KR locale).
- `EventRepository` + `SupabaseEventRepository` — R15 RPC 연결 (planned_events_for_range_kst / monthly_expense_kst / create_event / find_event_at).
- `DBEvent` DTO Codable.
- `MemoryCalendarStore.loadMonth(for:)` — KST 월 범위 기반 이벤트 + 월지출 병렬 fetch.
- `MonthlyExpenseHeader` — 캘린더 상단 `₩` 총액.
- `EventPlanSheet` — 제목 + 시작 + 여행 토글(종료 DatePicker) + 알람 토글(UNUserNotificationCenter 스케줄 · 권한 거부 시 이벤트는 저장).
- `CalendarView`: 미래 날짜 선택 → EventPlanSheet 오픈. 과거 날짜는 기존 memory list. 미래 날짜 cell 에는 memory dot 비활성.
- KSTDateFormatterTests + 자정 경계 커버.

## Files changed
- workspace/ios/Shared/KSTDateFormatter.swift (신규)
- workspace/ios/Shared/EventRepository.swift (신규)
- workspace/ios/Shared/DBModels.swift — DBEvent append
- workspace/ios/Features/Calendar/MemoryCalendarStore.swift — plannedEvents/monthlyExpense/isFutureDate/dayKind/loadMonth
- workspace/ios/Features/Calendar/MonthlyExpenseHeader.swift (신규)
- workspace/ios/Features/Calendar/EventPlanSheet.swift (신규)
- workspace/ios/Features/Calendar/CalendarView.swift — header + future branching + EventPlanSheet 호출
- workspace/ios/Shared/UnfadingLocalized.swift — Calendar namespace 확장 (14 keys)
- workspace/ios/Tests/KSTDateFormatterTests.swift (신규)

## Deferred
- memoryDates 를 실제 MemoryStore.memories 기반으로 교체 (현재 SampleMemoryPin 해시 기반). C1 에서 같이 수정.
- 알람 reminderAt < now 방어. R27 follow-up.
