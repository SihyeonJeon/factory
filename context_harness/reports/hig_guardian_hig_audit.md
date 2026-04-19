The Write tool is not available in this harness session, so I cannot write to the plan file directly. I'll present the full audit inline. Here is the complete HIG Guardian audit for Sprints 12–14:

---

## HIG Guardian Audit — Sprints 12–14

**Date:** 2026-04-14
**Auditor:** HIG Guardian (claude-sonnet-4-6)
**Scope:** Tab redesign (지도/캘린더/설정), CalendarView, SettingsView, PHAsset photo display, cluster photo markers, location permission on launch, MKLocalSearch place search
**Build:** BUILD SUCCEEDED · 79 tests passed / 0 failures
**Files read:** `UnfadingApp.swift`, `RootTabView.swift`, `CalendarView.swift`, `MonthlyCalendarGrid.swift`, `SettingsView.swift`, `MemoryClusterMapView.swift`, `PhotoLoader.swift`, `PlaceSearchService.swift`, `MainBottomSheet.swift`, `xcode_runtime_screenshot.png`

---

## Screenshot Evidence

The runtime screenshot shows the iOS system location-permission alert firing **immediately on cold launch**, before any user interaction. The standard map-first home screen is visible behind it with filter chips, the new three-tab bar (지도 / 캘린더 / 설정), and memory pin markers on the map.

---

## 🔴 BLOCKER Findings

### B-1 — Location permission requested on launch without user context

**File:** `App/UnfadingApp.swift:40`

```swift
.task {
    locationPermissionStore.handleCurrentLocationTap()   // fires on every cold launch
    ...
}
```

The screenshot confirms the system alert appears on first launch before any user gesture. HIG (Privacy → Requesting Permission): *"Request permission only when your app needs it — not at launch."* App Review Guideline 5.1.1 enforces this and rejects apps that present permission dialogs on cold start.

A user who hasn't yet tapped the map will deny and never re-enable. Apple will reject this on review.

**Fix:** Remove `handleCurrentLocationTap()` from `.task`. Fire it only when the user taps the current-location FAB — which is exactly what the method name implies the call site should be.

---

### B-2 — Map annotation and cluster views expose zero accessibility attributes

**File:** `Features/Home/MemoryClusterMapView.swift:164–237`

`grep accessibilityLabel MemoryClusterMapView.swift` → **zero matches**.

Both `configureMemoryView(_:for:)` and `configureClusterView(_:for:)` embed SwiftUI hosting views but set no `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`, or `isAccessibilityElement`. VoiceOver reads nothing meaningful from any map pin — the app's primary interactive surface is completely inaccessible.

**Fix — memory annotation:**
```swift
hostingView.view.isAccessibilityElement = true
hostingView.view.accessibilityLabel = annotation.memory.place.title
hostingView.view.accessibilityValue = annotation.memory.emotions.first?.title
hostingView.view.accessibilityHint = "탭하면 추억 상세 정보를 봅니다."
hostingView.view.accessibilityTraits = .button
```

**Fix — cluster annotation:**
```swift
hostingView.view.isAccessibilityElement = true
hostingView.view.accessibilityLabel = "추억 클러스터"
hostingView.view.accessibilityValue = "\(annotation.memberAnnotations.count)개의 추억"
hostingView.view.accessibilityHint = "탭하면 이 지역 추억 목록을 봅니다."
hostingView.view.accessibilityTraits = .button
```

---

## 🟡 ADVISORY Findings

### A-1 — Forced light mode shuts out dark-mode users

**File:** `App/UnfadingApp.swift:38`
```swift
.preferredColorScheme(.light)   // global, unoverridable
```
Users who need dark mode (OLED, low-vision, photosensitivity) cannot use their system preference. HIG expects apps to support both color schemes. Remove this modifier and implement dark-mode tokens in `UnfadingTheme`.

---

### A-2 — Sheet drag handle is near-invisible

**File:** `Features/Home/MainBottomSheet.swift:178`
```swift
Capsule().fill(UnfadingTheme.primary.opacity(0.3))
```
At 0.3 opacity against the light sheet background this is likely below WCAG AA contrast (4.5:1). VoiceOver path is correct (`accessibilityAdjustableAction`), but the sighted drag affordance is weak. Raise opacity to ≥ 0.6 or use `Color.secondary.opacity(0.5)` which adapts to color scheme.

---

### A-3 — Placeholder Settings rows look tappable but have no action

**File:** `Features/Settings/SettingsView.swift:119–127`

"개인정보 처리방침" and "문의하기" are plain `HStack`s inside a `List` — they get the standard tappable highlight but do nothing. VoiceOver reads them as interactive. Either remove them, apply `.disabled(true)`, or replace with a non-interactive `LabeledContent` style row.

---

### A-4 — MKLocalSearch result count silently capped at 5

**File:** `Shared/PlaceSearchService.swift:37`
```swift
results = Array(response.mapItems.prefix(5))
```
No UI communicates truncation. Raise to 10 (MapKit's natural max) or show `"\(response.mapItems.count)개 중 상위 5개"` in the results header.

---

### A-5 — Yearly recap toggle has no stable accessibility label

**File:** `Features/Calendar/CalendarView.swift:92`
```swift
Button(showsYearlyRecap || viewingDecember ? "접기" : "연간 리캡 보기") { ... }
```
Low priority. Add `.accessibilityHint(showsYearlyRecap ? "연간 리캡을 접습니다." : "연간 리캡을 펼칩니다.")` for cleaner VoiceOver narration.

---

## ✅ PASS Observations

| Area | Finding |
|------|---------|
| Tab bar | "지도 / 캘린더 / 설정" with SF Symbols; proper 3-tab layout |
| Month nav buttons | `frame(width:44, height:44)`; `accessibilityLabel` set |
| Calendar day cells | `minHeight: 52` ≥ 44pt; `accessibilityLabel` includes memory-present state |
| Filter clear button | `frame(minHeight: 44)` + `.contentShape(Rectangle())` (Sprint 11 fix carried forward) |
| Sheet VoiceOver | `accessibilityAdjustableAction` on handle; accessibility-size forces `.expanded` |
| PHImageRequestOptions | `isNetworkAccessAllowed: true` correct for photo-backed markers |
| NavigationStack | CalendarView + SettingsView both use `NavigationStack`, not deprecated `NavigationView` |
| Dynamic Type — sheet | `dynamicTypeSize.isAccessibilitySize` guard promotes sheet to `.expanded` automatically |

---

## Release Gate

| # | Finding | Severity | Blocks release? |
|---|---------|----------|-----------------|
| B-1 | Location permission on launch | BLOCKER | **YES** |
| B-2 | Map annotation/cluster zero accessibility | BLOCKER | **YES** |
| A-1 | Forced light mode | ADVISORY | No |
| A-2 | Low-contrast sheet handle | ADVISORY | No |
| A-3 | Fake-tappable placeholder rows | ADVISORY | No |
| A-4 | Silent search result cap | ADVISORY | No |
| A-5 | Yearly recap label semantics | ADVISORY | No |

**Verdict: BLOCKED — fix B-1 and B-2 before release.**

Post-fix evidence required: (a) runtime screenshot showing cold launch with **no** permission alert, and (b) VoiceOver Accessibility Inspector reading a map pin label.
