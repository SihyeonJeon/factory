# Sprint 17 — Code Drift Remediation

**Date:** 2026-04-14
**Source:** Architecture drift audit after Sprint 15
**Goal:** Fix hardcoded font + missing accessibility in Settings

---

## Fix 1: Hardcoded Font Size

In `Features/Rewind/YearEndReportView.swift` line 19:
```swift
// BEFORE (FORBIDDEN per coding conventions):
.font(.system(size: yearFontSize, weight: .bold, design: .rounded))

// AFTER:
.font(.system(.largeTitle, design: .rounded).weight(.bold))
```

If `yearFontSize` is a `@ScaledMetric`, that's acceptable. If it's a plain CGFloat constant, replace with semantic font.

---

## Fix 2: Settings Accessibility — Zero Labels

In `Features/Settings/SettingsView.swift`:
- Add `accessibilityLabel` to all interactive rows (그룹 관리, 프리미엄, 앱 정보, etc.)
- Add `accessibilityHint` to navigation links
- Placeholder rows (개인정보 처리방침, 문의하기) should have `.accessibilityTraits(.staticText)` since they're disabled

Example:
```swift
NavigationLink { ... } label: {
    Label("그룹 관리", systemImage: "person.3")
}
.accessibilityHint("그룹을 추가하거나 관리합니다.")

// Disabled placeholder rows:
HStack { ... }
    .accessibilityLabel("개인정보 처리방침")
    .accessibilityHint("준비 중입니다.")
    .accessibilityTraits(.staticText)
```

---

## Files to modify

| File | Action |
|---|---|
| `Features/Rewind/YearEndReportView.swift` | MODIFY — semantic font |
| `Features/Settings/SettingsView.swift` | MODIFY — add accessibility labels |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- All new text in Korean.
