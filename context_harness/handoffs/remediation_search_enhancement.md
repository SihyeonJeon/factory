# Remediation — Search Bar Enhancement (통합 검색 고도화)

**Date:** 2026-04-13
**Source:** Human feedback clarification on Sprint 8-A search bar
**Goal:** Upgrade simple place/note search to full date+memory search with autocomplete sections and map integration

---

## Current State

`UnfadingHomeView.swift` has a basic search bar that:
- Searches `place.title` and `note` on Memory objects
- Shows flat list of matching memories
- Tapping a result selects the marker and moves the camera

## Required Changes

### 1. Search placeholder text change
- `"장소 검색"` → `"데이트, 추억 검색"`

### 2. Autocomplete results: two sections

The `searchResultsOverlay` must show TWO sections:

**Section A — "데이트" (dates/events):**
- The data model: `DomainMemory` has `eventID: UUID?` linking to `DomainEvent` (which has `title: String`)
  - `EventStore` (EnvironmentObject) holds `events: [DomainEvent]`
  - A "데이트" = a `DomainEvent`. Search through `eventStore.events` matching `event.title`
  - For each matching event, count memories: `memoryStore.memories.filter { $0.eventID == event.id }.count`
- Show matching event titles with memory count badge (e.g., "홍대 데이트 (3)")
- The view already has `@EnvironmentObject var eventStore: EventStore` available — if not, inject it

**Section B — "추억" (memories):**
- Search `note`, `place.title` on individual Memory objects
- Show each matching memory with place name + note preview

Both sections filter as user types (case-insensitive, substring match).

### 3. Date selection behavior

When user taps a date result:
1. Clear `searchQuery` and dismiss search overlay
2. Set `dateFilter` state to the selected date/event title
3. **Bottom sheet**: filter to show ONLY memories belonging to that date
4. **Map**: calculate bounding region that contains ALL markers for that date's memories, then set `cameraPosition` to `.region(...)` that fits them all (use `regionToFit(memories:)` or equivalent)
5. **Markers**: select ALL markers for that date (use `MapSelection.cluster(memoryIDs, center)` or similar multi-select)
6. Show a filter chip at top of bottom sheet: "✕ {데이트이름}" — tapping X clears the filter and restores full view

### 4. Memory selection behavior

When user taps a memory result:
1. Clear `searchQuery` and dismiss search overlay
2. Select that memory's marker on the map: `mapSelectionStore.select(marker: memory.id)`
3. Move camera to that memory's coordinate
4. Set bottom sheet to mid-snap (0.48) showing that memory's summary (추억 간략히 보기)

### 5. New state properties needed

```swift
@State private var dateFilter: String? = nil
@State private var isSearchActive: Bool = false
```

### 6. Filter chip UI

When `dateFilter != nil`, show above the bottom sheet content or at the top of the curated grouping:
```swift
HStack {
    Text(dateFilter!)
        .font(.footnote.weight(.semibold))
    Button {
        dateFilter = nil
    } label: {
        Image(systemName: "xmark.circle.fill")
    }
}
.padding(.horizontal, 12)
.padding(.vertical, 6)
.background(Color.accentColor.opacity(0.15), in: Capsule())
```

### 7. Memory filtering integration

When `dateFilter` is set, `filteredMemories` (used by both map annotations and bottom sheet) should additionally filter by the date/event title. When `dateFilter` is nil, show all memories (existing behavior).

### 8. Clear button on search bar

Add a trailing clear button (xmark.circle.fill) in the search bar HStack that appears when `searchQuery` is not empty. Tapping it clears `searchQuery`.

---

## Files to edit

- `Features/Home/UnfadingHomeView.swift` — main changes (search overlay, state, filter logic, camera positioning)
- `Features/Home/MainBottomSheet.swift` — pass `dateFilter` binding, show filter chip, filter displayed memories
- `Features/Home/CuratedGrouping.swift` — accept optional `dateFilter` parameter to filter groups

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All 75 tests must pass.
- Do NOT break existing search functionality — enhance it.
- `DomainMemory.eventID` links to `DomainEvent` in `EventStore`. Use `eventStore.events` to resolve event titles.
- `EventStore` is already injected as an EnvironmentObject in the app. If `UnfadingHomeView` doesn't have it yet, add `@EnvironmentObject private var eventStore: EventStore`.
- For date selection, filter memories by `memory.eventID == selectedEvent.id`.
- For map region fitting, use all memories with matching eventID and compute MKCoordinateRegion that fits all their coordinates with some padding.
