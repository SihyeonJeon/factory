# Sprint 2 P1 — EventStore, Time Filter, Rewind Reminders

**Date:** 2026-04-12
**Prerequisite:** Sprint 2 P0 + Remediation r3 green (33/33 tests, evaluation passed)
**Goal:** Deliver 3 features + 2 test hygiene fixes. All tests green after.

---

## Feature 1: EventStore + Inline Event Creation (Epic 2)

### Acceptance criteria (from acceptance.md)
- Create or select an event container for a date, meetup, or trip span.
- Allow inline event creation when the user uploads the first memory and no current event exists for that time.
- Default new events to a single day and allow explicit promotion to a multi-day trip.
- Event containers support a single day by default and may optionally span multiple days.
- Multi-day behavior should require explicit user intent rather than being inferred automatically.
- The bottom-sheet memory list must visibly group content under a parent date or meetup.

### Implementation spec

1. **`Shared/Domain/EventStore.swift`** (NEW)
   - `@MainActor final class EventStore: ObservableObject`
   - `@Published var events: [DomainEvent]`
   - `func createEvent(title: String, groupID: UUID, startDate: Date, endDate: Date? = nil) -> DomainEvent`
   - `func activeEvent(for date: Date, in groupID: UUID) -> DomainEvent?` — returns event whose date range covers the given date
   - `func promoteToMultiDay(_ event: DomainEvent, endDate: Date)` — explicit multi-day promotion
   - Single-day events: `endDate == nil` or `endDate == startDate`

2. **`MemoryComposerSheet.swift` modification**
   - Before `saveMemory()`, check `eventStore.activeEvent(for: Date(), in: selectedGroup.id)`
   - If no active event: show inline "Create Event" section (title text field + optional end date picker)
   - If active event exists: show event name as a read-only label, auto-attach memory to it
   - `DomainMemory` must store `eventID: UUID?`

3. **`MainBottomSheet.swift` modification**
   - Group memories under their parent event title in the list
   - Use `Section(header:)` with event title + date range

4. **`App/MemoryMapApp.swift`** — inject `EventStore` as environment object

### Tests to add
- `testCreateEventSingleDay`
- `testActiveEventLookup`
- `testPromoteToMultiDay`
- `testComposerAutoAttachesActiveEvent`

---

## Feature 2: Time Filter on Map (Epic 3)

### Acceptance criteria
- Time filters animate pin appearance and disappearance.
- Support time filtering on the shared memory map.

### Implementation spec

1. **`MemoryMapHomeView.swift` modification**
   - The 4 filter chips (`All time`, `1 year`, `90 days`, `30 days`) already exist visually
   - Wire them to actually filter `memoryStore.memories` by `capturedAt` date
   - Add `@State private var selectedTimeFilter: TimeFilter = .allTime`
   - `enum TimeFilter { case allTime, oneYear, ninetyDays, thirtyDays }` with computed `cutoffDate: Date?`
   - Filtered annotations: `memoryStore.memories.filter { filter.includes($0) }`
   - Use `.animation(.easeInOut(duration: 0.3))` on the annotations array change for animated pin appearance/disappearance

2. **`MainBottomSheet.swift` modification**
   - Bottom sheet content should also respect the active time filter
   - Pass `timeFilter` binding or filtered memories array

### Tests to add
- `testTimeFilterAllTimeReturnsAll`
- `testTimeFilterThirtyDaysFilters`

---

## Feature 3: Rewind Reminder Configuration (Epic 4)

### Acceptance criteria
- Date-based rewind defaults to 10 AM and must be user-configurable.
- Location-based reminders must be individually switchable.
- Default location reminder radius is 200 m, adjustable from 100 m to 500 m.
- Support "N years ago today" reminders.
- Support optional location-based reminders.

### Implementation spec

1. **`Shared/RewindReminderStore.swift`** (NEW)
   - `@MainActor final class RewindReminderStore: ObservableObject`
   - `@Published var dateReminderEnabled: Bool = true`
   - `@Published var dateReminderTime: Date` — defaults to 10:00 AM
   - `@Published var locationReminderEnabled: Bool = false`
   - `@Published var locationRadiusMeters: Double = 200` — range 100...500
   - `func scheduleNotifications()` — uses `UNUserNotificationCenter`
   - `func cancelAllNotifications()`
   - On `dateReminderEnabled` or `dateReminderTime` change: reschedule

2. **`Features/Rewind/RewindSettingsView.swift`** (NEW)
   - Date reminder section: Toggle + DatePicker (hour/minute only)
   - Location reminder section: Toggle + Slider (100m–500m, step 50m)
   - Per-memory location reminder list with individual ON/OFF toggles

3. **`Features/Rewind/RewindFeedView.swift` modification**
   - Add navigation link or toolbar button to `RewindSettingsView`
   - Show "N years ago today" memories by filtering `memoryStore.memories` where `Calendar.isDate(capturedAt, equalTo: today, toGranularity: .day)` across years

4. **`App/MemoryMapApp.swift`** — inject `RewindReminderStore` as environment object

### Tests to add
- `testDefaultReminderTime10AM`
- `testLocationRadiusClamped`
- `testRewindFilterNYearsAgo`

---

## Test Hygiene (from code_review feedback)

### Fix 1: Delete duplicate test
- `MemoryMapTests.swift` — `testHomeSummarySheetEmptyState()` at ~line 315 is byte-for-byte identical to the test at ~line 310. **Delete the duplicate.**

### Fix 2: Add regression guard for Date.now fix
- Add `testComposerDraftSavesCurrentTimestamp()` — creates a `DomainMemory`, asserts `capturedAt` is between `before` and `after` timestamps (not a hardcoded constant).

---

## Constraints

- Do NOT rename or remove existing public APIs.
- Do NOT modify files outside the scope listed above.
- `DomainEvent` already exists in `MemoryDomain.swift` — extend it, don't duplicate.
- Inject new stores via `.environmentObject()` in `MemoryMapApp.swift`.
- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All existing 33 tests must pass. New tests bring total to ~42+.
- Search for leftover placeholders: `rg -n 'TODO\|FIXME\|HACK\|placeholder' workspace/ios/Features/ workspace/ios/Shared/`
