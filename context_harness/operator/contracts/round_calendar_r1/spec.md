# round_calendar_r1 spec
Base fa746a2.
## Deliverables
1. `workspace/ios/Features/Calendar/MemoryCalendarStore.swift` (@MainActor)
   - @Published displayedMonth: Date, selectedDate: Date?, memoryDates: Set<DateComponents> (year/month/day)
   - Methods: next/previousMonth(), select(_:), hasMemory(on: DateComponents) -> Bool, memoriesForSelectedDate() -> [SampleMemoryPin]
2. `workspace/ios/Shared/UnfadingMonthGrid.swift` — reusable month grid (7 cols × 5-6 rows), Korean weekday header, current-day ring, selected-day fill (coral), memory-day dot.
3. `workspace/ios/Features/Calendar/CalendarView.swift` — replace stub. Nav title "캘린더", month header with chevrons, UnfadingMonthGrid, below: DayMemoriesList (scrollable) showing memories for selected date; empty state with Korean placeholder.
4. `UnfadingLocalized.Calendar` extend: weekdayHeaders[7], monthYearFormat, emptyDayTitle, emptyDayBody, previousMonthHint, nextMonthHint, memoryCountFormat(count)
5. Tests for store + grid (≥ 6 new)

## Vibe-limits
Korean Locale/date math; 44pt day cells; a11y labels per day; no hardcoded fonts.

## Acceptance
- Build ✅, tests ≥ 69
- Runtime screenshot of Calendar tab
- Zero English literals, zero inline colors
