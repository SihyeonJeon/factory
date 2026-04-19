The Write tool is not available in this harness session — same constraint the HIG Guardian encountered. Presenting the full Visual QA report inline.

---

## Visual QA Report — Sprints 12–14

**Artifact:** `xcode_runtime_screenshot.png`
**Date:** 2026-04-14
**Build:** BUILD SUCCEEDED · 79 tests passed / 0 failures
**Auditor:** Visual QA (claude-sonnet-4-6)
**Scope:** Tab redesign (지도/캘린더/설정), CalendarView, SettingsView, PHAsset photo display, cluster photo markers, location permission on launch, MKLocalSearch place search
**Files read:** `UnfadingApp.swift`, `RootTabView.swift`, `MemoryClusterMapView.swift`, `SettingsView.swift`, `CalendarView.swift`

---

### Screenshot Read

The screenshot shows iPhone 17 (10:22), Dynamic Island at top with proper safe-area inset. Behind a system alert: map-first home screen, Korean city map with photo-backed pink circle memory markers, four filter chips (전체 기간 / 1년 / 90일 / 30일), FAB (+) top-right, and the new three-tab bar at bottom (지도 / 캘린더 / 설정). The system location-permission alert is rendered full-screen over all content, firing before any user gesture.

---

## BLOCKER Findings

### B-1 — Location permission alert fires on cold launch (screenshot-confirmed)

**File:** `App/UnfadingApp.swift:40`
**Evidence:** Screenshot directly shows the system alert before any user interaction.

```swift
.task {
    locationPermissionStore.handleCurrentLocationTap()  // fires on every cold launch
```

This is not gated by authorization status — it fires unconditionally. Apple App Review Guideline 5.1.1 rejects apps that present permission dialogs on cold start without user-initiated context. A first-time user who dismisses "허용 안 함" cannot recover without going to Settings.

**Fix:** Remove the call from `.task`. Fire `handleCurrentLocationTap()` only when the user taps the current-location FAB on the map. The method name already implies this is the correct call site.

---

### B-2 — Map annotation and cluster views expose zero accessibility attributes (code-verified)

**File:** `Features/Home/MemoryClusterMapView.swift:164–237`

Code inspection of `configureMemoryView(_:for:)` (line 164) and `configureClusterView(_:for:)` (line 204) confirms: neither sets `isAccessibilityElement`, `accessibilityLabel`, `accessibilityValue`, `accessibilityHint`, or `accessibilityTraits` on `hostingView.view`. The app's primary interactive surface — every memory pin and every cluster marker — is completely silent to VoiceOver.

**Fix — memory annotation (add inside `configureMemoryView`, after `hostingView.setRootView`):**
```swift
hostingView.view.isAccessibilityElement = true
hostingView.view.accessibilityLabel = annotation.memory.place.title
hostingView.view.accessibilityValue = annotation.memory.emotions.first?.title
hostingView.view.accessibilityHint = "탭하면 추억 상세 정보를 봅니다."
hostingView.view.accessibilityTraits = .button
```

**Fix — cluster annotation (add inside `configureClusterView`, after `hostingView.setRootView`):**
```swift
hostingView.view.isAccessibilityElement = true
hostingView.view.accessibilityLabel = "추억 클러스터"
hostingView.view.accessibilityValue = "\(annotation.memberAnnotations.count)개의 추억"
hostingView.view.accessibilityHint = "탭하면 이 지역 추억 목록을 봅니다."
hostingView.view.accessibilityTraits = .button
```

---

## ADVISORY Findings

### A-1 — Forced light mode (code-verified)

**File:** `App/UnfadingApp.swift:38`

```swift
.preferredColorScheme(.light)   // global, unoverridable
```

Blocks dark-mode users (OLED battery, photosensitivity, low-vision needs). Not a blocker for App Store submission but will generate user complaints. Remove and implement dark-mode color tokens.

---

### A-2 — Sheet drag handle near-invisible

**File:** `Features/Home/MainBottomSheet.swift:178`

```swift
Capsule().fill(UnfadingTheme.primary.opacity(0.3))
```

0.3 opacity against the light sheet background is likely below WCAG AA contrast (4.5:1). Raise opacity to ≥ 0.6 or use `Color.secondary.opacity(0.5)` which adapts to color scheme automatically.

---

### A-3 — Placeholder Settings rows appear interactive but do nothing

**File:** `Features/Settings/SettingsView.swift:119–127`

"개인정보 처리방침" and "문의하기" are plain `HStack`s in a `List` — they render with the standard tappable row highlight and show "준비 중" trailing text. Sighted users can read "준비 중" as a status signal, but VoiceOver still reads them as interactive buttons with no action. Mitigation: add `.accessibilityHint("준비 중입니다.")` or wrap in a non-interactive `LabeledContent` to suppress the button trait.

---

### A-4 — MKLocalSearch results silently capped at 5

**File:** `Shared/PlaceSearchService.swift:37`

No UI communicates truncation. Raise cap to 10 (MapKit's natural limit) or add a results header showing `"상위 5개 결과"`.

---

### A-5 — Yearly recap toggle label not stable

**File:** `Features/Calendar/CalendarView.swift:92`

```swift
Button(showsYearlyRecap || viewingDecember ? "접기" : "연간 리캡 보기") { ... }
```

Button already has `frame(minWidth: 44, minHeight: 44)` — tap target passes HIG. Low-priority: add `.accessibilityHint(showsYearlyRecap ? "연간 리캡을 접습니다." : "연간 리캡을 펼칩니다.")` for cleaner VoiceOver narration.

---

## PASS Observations

| Surface | Finding |
|---|---|
| Tab bar | 지도 / 캘린더 / 설정 with SF Symbols renders correctly; `RootTabView.swift` confirms `accessibilityLabel` + `accessibilityHint` on all three tabs |
| Photo markers | Pink circle memory markers with photo thumbnails visible on map — PHAsset display pipeline functional |
| Filter chips | 전체 기간 / 1년 / 90일 / 30일 visible, sized comfortably for finger targets |
| FAB | + button visible top-right, appears correctly layered above map |
| Dynamic Island | Title and controls sit below Dynamic Island with visible top padding |
| CalendarView structure | `NavigationStack` + large title; month nav, day grid, monthly summary, yearly recap, reminder sections all present |
| SettingsView structure | `NavigationStack` + large title; all NavigationLinks have `frame(minHeight: 44)` |
| Map safe area | No content clipped under tab bar or status area |

---

## New Surfaces Not Visible (QA Coverage Gap)

CalendarView, SettingsView, and cluster tap sheet are not shown in this single-state screenshot. These surfaces have been code-inspected above; no BLOCKER-level structural issues found beyond B-2 which affects all map surfaces. Request additional screenshots of:
1. CalendarView (monthly grid + yearly recap expanded)
2. SettingsView (설정 tab)
3. Cluster tap bottom sheet

---

## Release Gate

| # | Finding | Severity | Blocks release? |
|---|---|---|---|
| B-1 | Location permission on cold launch | **BLOCKER** | **YES** — App Review rejection risk |
| B-2 | Map annotation/cluster zero accessibility | **BLOCKER** | **YES** — Accessibility requirement |
| A-1 | Forced light mode | ADVISORY | No |
| A-2 | Low-contrast sheet handle | ADVISORY | No |
| A-3 | Fake-interactive Settings rows | ADVISORY | No |
| A-4 | Silent search result cap | ADVISORY | No |
| A-5 | Yearly recap label stability | ADVISORY | No |

**Verdict: BLOCKED — fix B-1 and B-2 before release.**

Post-fix evidence required:
- (a) Runtime screenshot showing cold launch with **no** permission alert
- (b) Accessibility Inspector reading a memory pin annotation label from `MemoryClusterMapView`
