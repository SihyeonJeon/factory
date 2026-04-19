# Sprint 9 — Core Interactions (바텀 시트 + 클러스터링 + 보관함 재설계)

**Date:** 2026-04-14
**Source:** Human Feedback Round 1 — HF-5, HF-6, HF-7
**Goal:** Fix bottom sheet snap, add marker clustering, redesign memory gallery in bottom sheet

---

## Task 1: Bottom Sheet Snap Fix (HF-5)

### Problem
손을 떼면 불필요한 액션이 한 번 더 발생. 스냅이 부자연스러움.

### Current Implementation
`MainBottomSheet.swift` — custom drag gesture with 3-snap points (0.18, 0.48, 0.92). Uses `.spring()` animation.

### Required Changes
- **Snap calculation**: When finger lifts, use velocity + position to determine target snap point. High velocity = skip to next snap. Low velocity = snap to nearest.
- **Spring animation**: Replace `.spring()` with `.spring(response: 0.35, dampingFraction: 0.8)` — faster response, less wobble
- **Remove double-action**: Ensure `onEnded` fires exactly once. Check if `onChange` + `onEnded` are both modifying the snap — if so, remove the onChange logic that sets snap.
- **Gesture state**: Use `@GestureState` for drag translation to auto-reset on gesture end, preventing stale state.

Implementation approach:
```swift
// In DragGesture.onEnded:
let velocity = value.predictedEndLocation.y - value.location.y
let projectedFraction = currentFraction + (velocity / screenHeight) * 0.3
let targetSnap = snapPoints.min(by: { abs($0 - projectedFraction) < abs($1 - projectedFraction) })!
withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
    sheetFraction = targetSnap
}
```

---

## Task 2: Marker Clustering (HF-6)

### Problem
지도 축소해도 마커들이 합쳐지지 않음.

### Implementation
Use MapKit's built-in clustering with `MKClusterAnnotation`:

1. **Create `MemoryAnnotation` class** (in `Shared/` or `Features/Home/`):
```swift
class MemoryAnnotation: NSObject, MKAnnotation, Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let memory: DomainMemory
    
    init(memory: DomainMemory) {
        self.id = memory.id
        self.coordinate = memory.place.coordinate
        self.memory = memory
    }
}
```

2. **Configure clustering**:
- Set `clusteringIdentifier = "memory"` on all MemoryAnnotation instances
- When using SwiftUI Map with `Annotation`, use the `clusterAnnotation` modifier or handle cluster rendering
- For SwiftUI MapKit (iOS 17+): use `MapContentBuilder` with `.annotationTitles(.hidden)` and custom cluster rendering

3. **Cluster tap behavior**:
- Tap cluster → zoom into that cluster region OR
- Tap cluster → show all cluster memories in bottom sheet (use `mapSelectionStore.select(cluster:)`)

4. **Visual**:
- Cluster marker: rounded circle with count badge, use `UnfadingTheme.primary` color
- Single marker: existing `MemoryPinMarker` (already styled)

---

## Task 3: Memory Gallery Redesign (HF-7) — 추억 보관함

### Current State
Bottom sheet shows `CuratedGrouping` with text-based memory list.

### New Design: Photo Gallery Style

#### 3.1 Default state (바텀 시트 기본)
- **Top section**: Curated highlights (keep existing `MemorySummaryCard`)
- **Bottom section**: "추억 보관함" gallery
  - Grouped by **데이트(이벤트)** name
  - Each group header: event title + date range + memory count
  - Under each group: **square photo grid** (3 columns, like iOS Photos app)
  - Photos from `memory.photoLocalIdentifiers`
  - If no photo: show a placeholder tile with the place name + emotion icon

#### 3.2 Photo tap → 추억 간략히 보기 (mid-snap)
- Tap a photo tile → bottom sheet animates to mid-snap (0.48)
- Shows **Memory Brief View** in bottom sheet:
  - Back button (← 뒤로) at top
  - Photo (larger), place name, date, note preview, emotion tags
  - Previous/Next arrows at bottom for sequential navigation
- Map simultaneously: camera moves to that memory's coordinate, marker selected

#### 3.3 Scroll down → 추억 상세 (full-snap)
- From "추억 간략히 보기" (mid-snap), user scrolls down
- Bottom sheet expands to full-snap (0.92) → becomes **추억 상세 페이지**
- Handle becomes hidden (but gesture still works)
- Full detail view: all photos, full note, cost, emotion tags, reactions, event info
- Feels like a full page

#### 3.4 Back navigation
- From 추억 상세: scroll up or tap back → sheet returns to mid-snap (0.48) → brief view
- From brief view: tap back → sheet returns to default state with gallery

#### 3.5 Map marker selection → same brief view
- Tap a marker on map → bottom sheet goes to mid-snap, shows that memory's brief view
- Same view as tapping a photo in gallery

#### 3.6 Cluster marker → filtered gallery
- Tap cluster marker → bottom sheet shows only memories in that cluster
- Grouped by date within the cluster
- Same photo grid layout, but filtered

#### 3.7 Multi-date memories
- Memories from different dates: group under their respective date headers
- Date headers sorted chronologically (newest first)

### Files to create/modify

| File | Action |
|---|---|
| `Features/Home/MemoryGalleryView.swift` | **NEW** — photo grid grouped by date |
| `Features/Home/MemoryBriefView.swift` | **NEW** — mid-snap brief view (간략히 보기) |
| `Features/Home/MemoryAnnotation.swift` | **NEW** — MKAnnotation subclass for clustering |
| `Features/Home/MainBottomSheet.swift` | MODIFY — integrate gallery, brief view, snap transitions |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — clustering setup, marker→brief navigation |
| `Features/Home/MemoryDetailView.swift` | MODIFY — integrate as full-snap content |
| `Features/Home/CuratedGrouping.swift` | MODIFY — add photo grid below curated summary |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All tests must pass (≥75).
- Bottom sheet snap must feel natural — no double-action, smooth spring animation.
- Clustering must work on zoom out.
- Photo grid must handle empty state gracefully.
- All new UI text must be in Korean.
- All new UI must use `UnfadingTheme` colors (from Sprint 8-B).
- All interactive elements must meet HIG 44pt minimum tap target.
