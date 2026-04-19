# Sprint 11 — Bottom Sheet Layout + Dummy Data + Search Sizing

**Date:** 2026-04-14
**Source:** Human Feedback Round 2 — HF2-2, HF2-3, HF2-9, HF2-10, HF2-12
**Goal:** Fix bottom sheet width/maximize, reposition FAB, compact search, add rich dummy data

---

## Task 1: Bottom Sheet Full-Width (HF2-2)

### Problem
`MainBottomSheet.swift` — 바텀 시트에 좌우 패딩/마진이 있어 화면 너비에 꽉 차지 않음.

### Implementation
- Remove any horizontal padding on the outer sheet container
- Sheet should span edge-to-edge (full screen width)
- Content inside may have its own padding, but the sheet background must be full-width
- Corner radius only on top corners: `.clipShape(UnevenRoundedRectangle(topLeadingRadius: UnfadingTheme.sheetRadius, topTrailingRadius: UnfadingTheme.sheetRadius))`
- Check `UnfadingHomeView.swift` overlay — if the sheet overlay has `.padding(.horizontal)`, remove it

---

## Task 2: FAB (+) Button Position (HF2-3)

### Problem
추억 만들기(+) 버튼이 위쪽에 동떨어져 있음.

### Implementation
- Move the FAB from its current position to sit **directly above the bottom sheet handle**
- The FAB should move WITH the sheet (anchored to sheet top)
- Position: right-aligned, just above the handle bar
- When sheet is at any snap position, FAB is always visible right above it
- In `UnfadingHomeView.swift`: move the FAB overlay to be part of the sheet overlay, positioned at the top of the sheet minus some offset

---

## Task 3: Bottom Sheet Maximize = Full Screen (HF2-9)

### Problem
최대화 시 핸들과 상단 여백이 여전히 보임.

### Implementation
- When sheet is at maximum snap (0.92 or whatever the top snap is):
  - Hide the handle bar (opacity → 0, or remove from layout)
  - Remove top padding/margin — content starts from safe area top
  - Sheet looks like a full-screen page
- When user drags down from maximized → show handle again, restore padding
- Animate the transition smoothly

```swift
// In MainBottomSheet:
private var isMaximized: Bool { 
    abs(sheetFraction - snapPoints.last!) < 0.02 
}

// Handle visibility
if !isMaximized {
    handleBar
}

// Top padding
.padding(.top, isMaximized ? 0 : 12)
```

---

## Task 4: Search Autocomplete Compact (HF2-10)

### Problem
검색 결과 리스트가 너무 크게 표시됨.

### Implementation
In `UnfadingHomeView.swift` `searchResultsOverlay`:
- Reduce result item padding: `12` → `8`
- Reduce font sizes: `.subheadline.weight(.semibold)` → `.footnote.weight(.semibold)` for titles
- Reduce note preview: `.footnote` → `.caption`
- Reduce section header size
- Reduce max overlay height: `220` → `180`
- Tighter vertical spacing between items: `8` → `4`
- Reduce the overall background corner radius

---

## Task 5: Rich Dummy Data (HF2-12)

### Problem
실제 데이터 없이 테스트하므로 문제 발견이 어려움.

### Implementation
In `Shared/SampleModels.swift`, create comprehensive sample data that loads on first launch:

```swift
// 3 Groups
static let sampleGroups: [DomainGroup] = [
    // 커플 그룹
    DomainGroup(name: "시현 ♥ 지은", mode: .couple, ownerID: sampleUserID),
    // 친구 그룹
    DomainGroup(name: "대학 동기 모임", mode: .generalGroup, ownerID: sampleUserID),
    DomainGroup(name: "회사 점심 메이트", mode: .generalGroup, ownerID: sampleUserID),
]

// 5 Events
static let sampleEvents: [DomainEvent] = [
    DomainEvent(groupID: ..., title: "홍대 데이트", startDate: ...),
    DomainEvent(groupID: ..., title: "제주도 여행", startDate: ..., endDate: ...), // multi-day
    DomainEvent(groupID: ..., title: "한강 피크닉", startDate: ...),
    DomainEvent(groupID: ..., title: "강남 맛집 탐방", startDate: ...),
    DomainEvent(groupID: ..., title: "부산 여행", startDate: ..., endDate: ...),
]

// 20 Memories with diverse data
// Locations: 서울 (홍대, 강남, 한강, 경복궁), 제주 (성산일출봉, 협재해변), 부산 (해운대, 감천문화마을)
// Each with: note, emotions, cost, place coordinates
// Spread across different dates in the last year
// Some with photos (use placeholder identifiers), some without
```

**Important:** Update `MemoryStore`, `GroupStore`, `EventStore` to load these samples when the stores are empty (first launch). Check if they already have sample loading logic and extend it.

Coordinates for Korean locations:
- 홍대: 37.5563, 126.9220
- 강남역: 37.4979, 127.0276
- 한강공원: 37.5170, 126.9369
- 경복궁: 37.5796, 126.9770
- 성산일출봉: 33.4592, 126.9425
- 협재해변: 33.3940, 126.2396
- 해운대: 35.1587, 129.1604
- 감천문화마을: 35.0975, 129.0108
- 북촌한옥마을: 37.5826, 126.9831
- 이태원: 37.5340, 126.9948

---

## Files to edit

| File | Changes |
|---|---|
| `Features/Home/MainBottomSheet.swift` | Full-width, maximize behavior, handle visibility |
| `Features/Home/UnfadingHomeView.swift` | FAB position, search overlay compacting, sheet overlay padding |
| `Shared/SampleModels.swift` | Rich dummy data (groups, events, 20 memories) |
| `Shared/Domain/MemoryStore.swift` | Load samples on first launch |
| `Shared/Domain/GroupStore.swift` | Load samples on first launch |
| `Shared/Domain/EventStore.swift` | Load samples on first launch |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All tests must pass (≥79).
- All new UI text in Korean.
- Use UnfadingTheme colors.
- All tap targets ≥ 44pt.
