# Sprint 15 — Visual Polish + Advisory Fixes

**Date:** 2026-04-14
**Source:** Evaluation advisories + screenshot review
**Goal:** Fix remaining advisory items for App Store readiness

---

## Task 1: Sheet Handle Contrast (A-2)

In `Features/Home/MainBottomSheet.swift`:
- Find the handle capsule `Capsule().fill(UnfadingTheme.primary.opacity(0.3))`
- Change opacity from 0.3 to 0.5 for better visibility against light background

---

## Task 2: Placeholder Settings Rows (A-3)

In `Features/Settings/SettingsView.swift`:
- Find "개인정보 처리방침" and "문의하기" rows
- Add `.disabled(true)` and `.foregroundStyle(UnfadingTheme.textSecondary)` to indicate they're placeholders
- Or replace with `Text` views instead of tappable rows

---

## Task 3: Place Search Result Count (A-4)

In `Shared/PlaceSearchService.swift`:
- Change `prefix(5)` to `prefix(8)` for more results
- Or keep at 5 but add a count indicator in the search overlay

In `Features/Home/UnfadingHomeView.swift`:
- In the place search section header, show the count if truncated:
  `"장소 (\(placeSearchService.results.count)개)"` 

---

## Task 4: Yearly Recap Accessibility (A-5)

In `Features/Calendar/CalendarView.swift`:
- Add `.accessibilityHint()` to the yearly recap toggle button:
```swift
Button(showsYearlyRecap || viewingDecember ? "접기" : "연간 리캡 보기") { ... }
    .accessibilityHint(showsYearlyRecap ? "연간 리캡을 접습니다." : "연간 리캡을 펼칩니다.")
```

---

## Task 5: MemoryComposerSheet Photo Preview

In `Features/Home/MemoryComposerSheet.swift`:
- If the composer has photo selection, use `AsyncPhotoView` for previewing selected photos
- Ensure photo previews use the same `PhotoLoader` as the rest of the app

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/MainBottomSheet.swift` | MODIFY — handle opacity |
| `Features/Settings/SettingsView.swift` | MODIFY — placeholder rows |
| `Shared/PlaceSearchService.swift` | MODIFY — result count |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — place search count display |
| `Features/Calendar/CalendarView.swift` | MODIFY — recap a11y hint |
| `Features/Home/MemoryComposerSheet.swift` | MODIFY — photo preview with AsyncPhotoView |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- All new UI text in Korean.
- Use UnfadingTheme.
