# Remediation — Sprint 11 Advisory Items

**Date:** 2026-04-14
**Source:** Sprint 11 HIG Guardian + Visual QA advisory findings
**Goal:** Fix contextual button touch targets

---

## Fix 1: Contextual overlay button touch targets (A1)

In `Features/Home/MainBottomSheet.swift`, find the `overlayHeader` computed property (~line 280-330):

1. **Active filter clear button** — add `.frame(minHeight: 44)` to its label HStack
2. **"선택 해제" button** — add `.frame(minHeight: 44)` to the button

Both should also have `.contentShape(Rectangle())` to expand the tap target.

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/MainBottomSheet.swift` | MODIFY — touch target fixes |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
