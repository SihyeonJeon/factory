# Sprint 5 — Group Timeline & Yearly Recap Statistics

**Date:** 2026-04-13
**Prerequisite:** Sprint 4 + Remediation r7 green (59/59 tests)
**Goal:** 2 nice-to-have features from acceptance.md. All tests green after.

---

## Feature 1: Group Timeline View

### Acceptance criteria (from "Nice to have")
- Group timeline showing chronological memory history per group.

### Implementation spec

1. **`Features/Groups/GroupTimelineView.swift`** (NEW)
   - Takes a `DomainGroup` as input
   - Shows all memories for that group sorted by `capturedAt` descending
   - Grouped by month/year using `Section(header:)` with formatted date headers
   - Each row shows: place title, note preview (1 line), emotion icon, photo count badge, optional cost
   - Tap navigates to `MemoryDetailView`
   - Empty state: `ContentUnavailableView("No memories yet", systemImage: "clock", description: "Memories you record in this group will appear here as a timeline.")`

2. **`Features/Groups/GroupHubView.swift`** modification
   - Add a `NavigationLink` row "Timeline" with `systemImage: "clock.arrow.circlepath"` for each group
   - Links to `GroupTimelineView(group: group)`

---

## Feature 2: Yearly Recap Statistics

### Acceptance criteria (from "Nice to have")
- Yearly recap statistics showing memory activity summary.

### Implementation spec

1. **`Shared/Domain/MemoryStore.swift`** modification
   - Add computed method:
     ```swift
     func yearlyRecap(year: Int, calendar: Calendar = .current) -> YearlyRecap {
         let yearMemories = memories.filter { calendar.component(.year, from: $0.capturedAt) == year }
         let uniquePlaces = Set(yearMemories.map(\.place.title))
         let topEmotion = yearMemories.flatMap(\.emotions)
             .reduce(into: [:]) { $0[$1, default: 0] += 1 }
             .max(by: { $0.value < $1.value })?.key
         let totalCost = yearMemories.compactMap(\.cost).reduce(0, +)
         let monthlyBreakdown = Dictionary(grouping: yearMemories) { calendar.component(.month, from: $0.capturedAt) }
             .mapValues(\.count)
         return YearlyRecap(
             year: year,
             totalMemories: yearMemories.count,
             uniquePlaces: uniquePlaces.count,
             topEmotion: topEmotion,
             totalCost: totalCost,
             monthlyBreakdown: monthlyBreakdown
         )
     }
     ```

2. **`Shared/Domain/YearlyRecap.swift`** (NEW)
   ```swift
   struct YearlyRecap: Equatable {
       let year: Int
       let totalMemories: Int
       let uniquePlaces: Int
       let topEmotion: EmotionTag?
       let totalCost: Double
       let monthlyBreakdown: [Int: Int] // month number → memory count
   }
   ```

3. **`Features/Rewind/YearlyRecapView.swift`** (NEW)
   - Shows recap statistics for a selected year
   - Stats grid: total memories, unique places, top emotion, total cost (KRW)
   - Simple bar chart showing monthly memory count (12 bars, one per month)
   - Year picker (Picker with wheel style) to switch between years
   - Accessible: each stat has `.accessibilityLabel`

4. **`Features/Rewind/RewindFeedView.swift`** modification
   - Add a `NavigationLink` in the toolbar or as a section header: "Yearly Recap" with `systemImage: "chart.bar"`
   - Links to `YearlyRecapView()`

### Tests to add
- `testYearlyRecapCountsMemories` — add 3 memories in 2025, verify recap.totalMemories == 3
- `testYearlyRecapUniquePlaces` — add 2 memories at same place + 1 different, verify uniquePlaces == 2
- `testYearlyRecapTopEmotion` — add memories with joy(2) + calm(1), verify topEmotion == .joy
- `testYearlyRecapTotalCost` — add memories with costs 10000 + 20000, verify totalCost == 30000
- `testGroupTimelineFiltersCorrectGroup` — add memories in 2 groups, verify timeline returns only matching group

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 59 existing tests must pass. New tests bring total to ~64.
