# Sprint 12 — Tab Bar Redesign + Calendar Page + Bottom Sheet Motion

**Date:** 2026-04-14
**Source:** Human Feedback Round 2 — HF2-7, HF2-1, HF2-6
**Goal:** Replace 3-tab layout, create calendar page, fix sheet clipping and motion

---

## Task 1: Tab Bar Redesign (HF2-7)

### Current
3 tabs: 지도 / 되감기 / 그룹 — with liquid glass background that obscures content behind it.

### New Structure
3 tabs: **지도** / **캘린더** / **설정**

#### Changes in `App/RootTabView.swift`:
```swift
TabView(selection: $tabRouter.selected) {
    UnfadingHomeView(evidenceMode: evidenceMode)
        .tabItem { Label("지도", systemImage: "map") }
        .tag(AppTab.map)
    
    CalendarView()
        .tabItem { Label("캘린더", systemImage: "calendar") }
        .tag(AppTab.calendar)
    
    SettingsView()
        .tabItem { Label("설정", systemImage: "gearshape") }
        .tag(AppTab.settings)
}
```

#### Tab bar styling:
- Remove liquid glass / `.regularMaterial` from tab bar
- Use opaque `UnfadingTheme.sheetBackground` or `.toolbarBackground(.visible, for: .tabBar)` with solid warm color
- Tint: `UnfadingTheme.primary`

#### Update `Shared/TabRouter.swift`:
- Change `AppTab` enum: `.map`, `.calendar`, `.settings` (remove `.rewind`, `.groups`)

### "되감기" content integration:
- Rewind moments/reminders → move to bottom sheet main curation (already partially there via HomeSummarySheet)
- RewindFeedView content → embed in bottom sheet's default view or curated section

---

## Task 2: Calendar Page (NEW)

Create `Features/Calendar/CalendarView.swift`:

### Layout:
1. **Month calendar grid** at top
   - Standard month view with day numbers
   - Days that have memories: show a colored dot below the number (UnfadingTheme.primary)
   - Today highlighted
   - Swipe left/right to change months
   - Use SwiftUI's native date capabilities or a simple LazyVGrid

2. **Selected day's memories** below calendar
   - Tap a day → show list of memories for that date
   - Each memory card: photo thumbnail, place name, note preview, cost
   - If no memories on that day: "이 날의 추억이 없어요"

3. **Monthly summary** section
   - 한 달 총 지출: sum of all memory costs for the month
   - 추억 수: count of memories
   - 방문 장소 수: unique places

4. **Year-end recap** section (moved from Rewind tab)
   - Integrate `YearlyRecapView` content as a section
   - Show when viewing December or via a "연간 리캡 보기" button

5. **Reminder settings** section (moved from Rewind tab)
   - Integrate `RewindSettingsView` content
   - Or link to it from calendar settings

---

## Task 3: Settings Page (NEW)

Create `Features/Settings/SettingsView.swift`:

### Layout:
1. **그룹 관리** section
   - List of user's groups (from GroupStore)
   - Create group, join group buttons
   - Tap group → group detail (existing GroupHubView content)

2. **프리미엄** section
   - Link to PremiumUpgradeView

3. **앱 정보** section
   - Version
   - 개인정보 처리방침 (placeholder)
   - 문의하기 (placeholder)

4. **다이어리 커버** section
   - Link to DiaryCoverCustomizationView

5. **지도 테마 / 핀 아이콘** section
   - Links to MapThemePickerView, PinIconPackPickerView

---

## Task 4: Bottom Sheet Detail View Clipping Fix (HF2-1)

### Problem
추억 간략히 보기 → 확장 → 상세 보기 진입 시 상단이 잘림.

### Implementation
In `MainBottomSheet.swift` / `MemoryDetailView.swift`:
- When transitioning to detail (full-snap), ensure content starts from safe area top
- Add `.ignoresSafeArea(.all, edges: .top)` on the sheet when maximized, or adjust content offset
- The detail view ScrollView should have proper top padding to account for status bar

---

## Task 5: Bottom Sheet Motion Polish (HF2-6)

### Problem
스크롤과 핸들 드래그가 여전히 어색.

### Implementation
- Use `UIScrollView` coordination: when scroll is at top and user pulls down → sheet should start dragging down
- When sheet is not at max → drag gesture controls sheet position
- When sheet is at max → scroll view handles scrolling, pull-down at top transitions to drag
- Consider using `ScrollViewReader` + `onScrollGeometryChange` (iOS 18+) to detect scroll position
- Alternative: use `.presentationDetents` for the bottom sheet instead of custom overlay if it provides better gesture handling (but keep the custom snap points)
- Spring parameters: `.spring(response: 0.32, dampingFraction: 0.82)` — slightly faster and more damped

---

## Files to create/modify

| File | Action |
|---|---|
| `App/RootTabView.swift` | MODIFY — new tab structure |
| `Shared/TabRouter.swift` | MODIFY — new AppTab enum |
| `Features/Calendar/CalendarView.swift` | **NEW** — calendar page |
| `Features/Calendar/MonthlyCalendarGrid.swift` | **NEW** — month grid with dots |
| `Features/Calendar/DayMemoriesList.swift` | **NEW** — memories for selected day |
| `Features/Settings/SettingsView.swift` | **NEW** — settings page |
| `Features/Home/MainBottomSheet.swift` | MODIFY — motion polish, clipping fix |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — rewind integration in curation |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All tests must pass (≥79).
- All UI text in Korean.
- Use UnfadingTheme colors throughout.
- All tap targets ≥ 44pt.
- Calendar must handle months with no memories gracefully.
- Existing RewindFeedView/RewindSettingsView content should be reused, not rewritten.
