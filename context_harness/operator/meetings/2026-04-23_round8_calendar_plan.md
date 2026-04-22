---
round: round_calendar_r1
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round8-calendar
contract_hash: none
created_at: 2026-04-23T02:45:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---

# R8 — Calendar full implementation

## Scope
Replace CalendarView stub with real month grid. Day dot when memory exists for that date. Selected date → DayMemoriesList below grid. Korean weekday headers.

## Deliverables
- `Features/Calendar/CalendarView.swift` (replace stub)
- `Features/Calendar/MemoryCalendarStore.swift` (new @MainActor store)
- `Shared/UnfadingMonthGrid.swift` (reusable month grid component)
- `Tests/MemoryCalendarStoreTests.swift` + `UnfadingMonthGridTests.swift`
- `UnfadingLocalized.Calendar` extended

## Decision
PROCEED. Codex dispatched.

## Challenge Section
### Risk
Date math + week-start (Sunday vs Monday) + Korean locale = edge cases. Mitigation: use `Calendar(identifier: .gregorian)` with `Locale(identifier: "ko_KR")` and compute via `firstWeekday`.
### Rejected alt
Embed UIKit UICalendarView. Rejected: SwiftUI-native for consistency with rest of app.
### Objection
Sample memory-dates need to be generated deterministically (no real persistence until R11). Accept as placeholder.
