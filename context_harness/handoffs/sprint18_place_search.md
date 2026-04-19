# Sprint 18 — ManualPlacePickerSheet: Real Place Search Integration

**Date:** 2026-04-14
**Source:** MemoryComposerSheet audit — ManualPlacePickerSheet uses only 3 hardcoded PlaceSuggestions
**Goal:** Integrate PlaceSearchService (MKLocalSearch) into ManualPlacePickerSheet for real search results

---

## Problem

`ManualPlacePickerSheet` (line 923 in MemoryComposerSheet.swift) only uses `PlaceSuggestion.matching()` which filters 3 hardcoded samples. The `PlaceSearchService` (Shared/PlaceSearchService.swift) already wraps MKLocalSearch but is NOT used in the composer.

---

## Fix: Wire PlaceSearchService into ManualPlacePickerSheet

In `Features/Home/MemoryComposerSheet.swift`, modify `ManualPlacePickerSheet` (line 923+):

### Changes required:

1. Add `@StateObject private var placeSearch = PlaceSearchService()` to ManualPlacePickerSheet
2. Call `placeSearch.search(query:)` on searchText change (use `.onChange(of: searchText)`)
3. Add a new Section for MKLocalSearch results above the existing "주변 추천" section
4. Each search result row: show `mapItem.name` + `mapItem.placemark.title`, map icon, 44pt min height
5. Selecting a search result creates `SelectedPlace(title: name, coordinate: mapItem.placemark.coordinate)` and dismisses
6. Show `ProgressView()` when `placeSearch.isSearching`
7. Keep the existing "주변 추천" section with `PlaceSuggestion.samples` as fallback when search is empty
8. Call `placeSearch.cancel()` on dismiss

### Layout:

```
[검색 바]                          ← existing .searchable
────────────────────────────────
검색 결과 (MKLocalSearch)          ← NEW section, only when searchText ≥ 2 chars
  ProgressView (searching...)      ← while isSearching
  mapItem.name                     ← each result row
  mapItem.placemark.locality
────────────────────────────────
입력한 장소 사용                    ← existing section (typed title)
────────────────────────────────
주변 추천                          ← existing section (static suggestions, shown when search empty)
```

### Accessibility:

- Each search result row: `.accessibilityLabel(mapItem.name ?? "장소")` + `.accessibilityHint("이 장소를 선택합니다.")`
- ProgressView: `.accessibilityLabel("장소 검색 중")`

### Contract:

```swift
// PlaceSearchService (already exists, DO NOT MODIFY):
// Input:  search(query: String, region: MKCoordinateRegion? = nil)
// Output: @Published var results: [MKMapItem]
// Output: @Published var isSearching: Bool
// Side effect: cancel() clears results and stops search
```

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/MemoryComposerSheet.swift` | MODIFY — ManualPlacePickerSheet에 PlaceSearchService 통합 |

**DO NOT modify:** `Shared/PlaceSearchService.swift`, `Shared/SampleModels.swift`

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- All new UI text in Korean.
- 44pt minimum touch targets on all interactive elements.
- UnfadingTheme colors only.
