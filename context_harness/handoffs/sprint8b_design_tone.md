# Sprint 8-B — Design Tone Change (따뜻한 커플 감성)

**Date:** 2026-04-14
**Source:** Human Feedback Round 1 — HF-3, HF-9
**Goal:** Transform the app from cold "Apple Liquid Glass" aesthetic to warm, cute Korean couple diary aesthetic

---

## Design Direction

**현재 문제:** 딱딱한 애플 리퀴드 글래스 느낌 — `.regularMaterial`, 시스템 블루 accent, 기본 iOS 크롬
**목표:** 한국 20~30대 커플 앱 감성 — 둥근 모서리, 파스텔 색상, 따뜻한 타이포그래피

참고 앱 톤: Between, 비트윈, 커플 다이어리, 포토부스 앱

---

## Task 1: Color Palette (UnfadingTheme)

Create a new file `Shared/UnfadingTheme.swift` with a centralized color palette:

```swift
import SwiftUI

enum UnfadingTheme {
    // Primary: warm coral/peach
    static let primary = Color(red: 0.96, green: 0.60, blue: 0.55)        // #F5998C — soft coral
    static let primaryLight = Color(red: 0.98, green: 0.78, blue: 0.74)   // #FAC7BC — light peach
    
    // Secondary: warm lavender
    static let secondary = Color(red: 0.76, green: 0.69, blue: 0.87)      // #C2B0DE — soft lavender
    static let secondaryLight = Color(red: 0.89, green: 0.85, blue: 0.95) // #E3D9F2 — pastel lavender
    
    // Background surfaces
    static let cardBackground = Color(red: 1.0, green: 0.98, blue: 0.96)  // #FFFAF5 — warm cream
    static let sheetBackground = Color(red: 1.0, green: 0.97, blue: 0.94) // #FFF8F0 — warm ivory
    static let surfaceOverlay = Color(red: 0.98, green: 0.95, blue: 0.92) // #FAF2EB — soft sand
    
    // Text
    static let textPrimary = Color(red: 0.25, green: 0.22, blue: 0.20)    // #403833 — warm dark brown
    static let textSecondary = Color(red: 0.55, green: 0.50, blue: 0.47)  // #8C8078 — warm gray
    
    // Accent
    static let accent = Color(red: 0.96, green: 0.60, blue: 0.55)         // same as primary — coral
    static let accentSoft = Color(red: 0.96, green: 0.60, blue: 0.55).opacity(0.15)
    
    // Emotion/tag chip colors (pastels)
    static let chipBackground = Color(red: 0.96, green: 0.92, blue: 0.88) // #F5EBE1
    
    // Corner radius
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16
    static let chipRadius: CGFloat = 12
    static let sheetRadius: CGFloat = 28
}
```

---

## Task 2: Apply Theme to ALL Views

### RootTabView.swift
- `.tint(Color.accentColor)` → `.tint(UnfadingTheme.primary)`

### UnfadingHomeView.swift (Home)
- **Top header banner**: 
  - `.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))` → `.background(UnfadingTheme.sheetBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: UnfadingTheme.sheetRadius))`
  - Add subtle shadow: `.shadow(color: UnfadingTheme.primary.opacity(0.08), radius: 12, y: 4)`
  - "Unfading" title: add `.foregroundStyle(UnfadingTheme.primary)` warm coral color
  - Subtitle: `.foregroundStyle(UnfadingTheme.textSecondary)`
- **Search bar**: 
  - Background: `Color.primary.opacity(0.06)` → `UnfadingTheme.surfaceOverlay`
  - Icon: `.foregroundStyle(.secondary)` → `.foregroundStyle(UnfadingTheme.textSecondary)`
- **Filter chips**:
  - Selected: `Color.accentColor` → `UnfadingTheme.primary`
  - Unselected border: `Color.primary.opacity(0.14)` → `UnfadingTheme.primary.opacity(0.2)`
  - Selected text: keep `.white`
  - Unselected text: `.primary` → `UnfadingTheme.textPrimary`
- **Cluster bubble**: `Color.blue.opacity(0.92)` → `UnfadingTheme.primary`
- **Search results overlay**: `Color.white.opacity(0.82)` → `UnfadingTheme.cardBackground`
- **FAB (+) button** (if present): use `UnfadingTheme.primary` background with white icon

### MainBottomSheet.swift
- **Sheet background**: `.regularMaterial` or any material → `UnfadingTheme.sheetBackground.opacity(0.97)`
- **Handle bar**: use `UnfadingTheme.primary.opacity(0.3)` instead of gray
- **Corner radius**: use `UnfadingTheme.sheetRadius`
- **Filter chip** (date filter): `Color.accentColor.opacity(0.15)` → `UnfadingTheme.accentSoft`

### MemorySummaryCard.swift
- Card background → `UnfadingTheme.cardBackground`
- Tag chips → `UnfadingTheme.chipBackground` with `UnfadingTheme.chipRadius`

### CuratedGrouping.swift
- Empty state text → `UnfadingTheme.textSecondary`

### MemoryDetailView.swift
- Section headers → `UnfadingTheme.textSecondary`
- Card backgrounds → `UnfadingTheme.cardBackground`
- Navigation buttons → `UnfadingTheme.primary`

### MemoryComposerSheet.swift
- Accent/tint → `UnfadingTheme.primary`
- Save/Cancel buttons → warm coral theme
- Section headers → `UnfadingTheme.textSecondary`

### MemoryPinMarker.swift
- Default pin color → `UnfadingTheme.primary` instead of system red/blue

### GroupHubView.swift
- Group cards → `UnfadingTheme.cardBackground`
- Create/Join buttons → `UnfadingTheme.primary`
- Section styling → warm palette

### GroupTimelineView.swift
- Timeline cards → `UnfadingTheme.cardBackground`
- Date headers → `UnfadingTheme.textSecondary`

### DiaryCoverCustomizationView.swift
- Cover themes → warm palette integration

### MapThemePickerView.swift / PinIconPackPickerView.swift
- Selection highlight → `UnfadingTheme.primary`
- Card backgrounds → `UnfadingTheme.cardBackground`

### PremiumUpgradeView.swift
- Upgrade button → `UnfadingTheme.primary` with white text
- Section backgrounds → warm palette

### RewindFeedView.swift / RewindMomentCard.swift / RewindSettingsView.swift
- Cards → `UnfadingTheme.cardBackground`
- Accent → `UnfadingTheme.primary`

### YearEndReportView.swift / YearlyRecapView.swift
- Report cards → warm palette
- Charts/highlights → coral/lavender palette

### HomeSummarySheet.swift
- Content → warm palette

---

## Task 3: Typography Warmth

- App title "Unfading": use `.title2.weight(.bold)` with rounded design: `.font(.system(.title2, design: .rounded, weight: .bold))`
- Subtitle "우리의 흐려지지 않는 추억": `.font(.system(.subheadline, design: .rounded))`
- Section headers: use `.system(..., design: .rounded)` where possible for warmth
- Do NOT change Dynamic Type compliance — all fonts must remain scalable

---

## Task 4: Subtle Polish

- Add gentle shadows to cards: `.shadow(color: UnfadingTheme.primary.opacity(0.06), radius: 8, y: 2)`
- Bottom sheet handle: slightly wider and more rounded, coral-tinted
- Empty states: use warmer messaging tone (already in Korean)

---

## Files to edit

| File | Changes |
|---|---|
| `Shared/UnfadingTheme.swift` | **NEW** — centralized color palette |
| `App/RootTabView.swift` | tint color |
| `Features/Home/UnfadingHomeView.swift` | header, search, chips, clusters, search overlay |
| `Features/Home/MainBottomSheet.swift` | sheet background, handle, filter chip |
| `Features/Home/MemorySummaryCard.swift` | card bg, tags |
| `Features/Home/CuratedGrouping.swift` | empty state |
| `Features/Home/MemoryDetailView.swift` | sections, buttons |
| `Features/Home/MemoryComposerSheet.swift` | tint, sections |
| `Features/Home/MemoryPinMarker.swift` | pin color |
| `Features/Home/HomeSummarySheet.swift` | content |
| `Features/Groups/GroupHubView.swift` | cards, buttons |
| `Features/Groups/GroupTimelineView.swift` | timeline |
| `Features/Groups/DiaryCoverCustomizationView.swift` | covers |
| `Features/Groups/MapThemePickerView.swift` | selection |
| `Features/Groups/PinIconPackPickerView.swift` | selection |
| `Features/Settings/PremiumUpgradeView.swift` | buttons, sections |
| `Features/Rewind/RewindFeedView.swift` | cards |
| `Features/Rewind/RewindMomentCard.swift` | card |
| `Features/Rewind/RewindSettingsView.swift` | settings |
| `Features/Rewind/YearEndReportView.swift` | report |
| `Features/Rewind/YearlyRecapView.swift` | recap |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All 75 tests must pass.
- Do NOT break any existing functionality — this is a visual-only change.
- All fonts must remain Dynamic Type compliant (no hardcoded sizes).
- Warm palette must be consistent across ALL views — no cold blue/gray remnants.
