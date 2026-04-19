# Remediation Round 3 — Sprint 2 P0 Post-Evaluation Fixes

**Date:** 2026-04-12
**Trigger:** HIG guardian + visual QA flagged 2 P1 + 3 P2 blockers after Sprint 2 P0 delivery.
**Goal:** Fix all 5 items, keep 32/32 tests green.

---

## Files in scope

- `workspace/ios/Features/Home/MemoryComposerSheet.swift`
- `workspace/ios/Features/Home/MemoryMapHomeView.swift`
- `workspace/ios/Features/Home/MemoryDetailView.swift`
- `workspace/ios/Features/Home/MainBottomSheet.swift`
- `workspace/ios/Tests/MemoryMapTests.swift` (if tests need updating)

---

## Fixes required

### P1-1: Hardcoded date string (MemoryComposerSheet.swift:103)

**Current:** `Text("Today, 8:40 PM")`
**Fix:** Replace with `Text(Date.now, style: .time)` or `Text(Date.now, format: .dateTime.hour().minute())`.
The string must show the actual current time, not a static placeholder.

### P1-2: Placeholder event label (MemoryComposerSheet.swift:98)

**Current:** `"Memory draft"` appears as a visible label to users.
**Fix:** Remove the row entirely, or replace with `Text("–")`. Do NOT ship placeholder copy.

### P2-1: Hardcoded Seoul coordinates (MemoryMapHomeView.swift:41-46)

**Current:** Map camera initializes to hardcoded Seoul coordinates (likely `37.5665, 126.9780`).
**Fix:** Use `.userLocation(fallback: .automatic)` for the initial map region, or use `locationPermissionStore.currentCoordinate` if available, falling back to `.automatic`.
Check line 496 as well — visual QA flagged two sites with hardcoded Seoul coords.

### P2-2: Previous/Next buttons not disabled at boundaries (MemoryDetailView.swift:103,109)

**Current:** "Previous" and "Next" navigation buttons are never `.disabled()` when at the first or last item.
**Fix:** Add `.disabled(currentIndex == 0)` for Previous and `.disabled(currentIndex == memories.count - 1)` for Next (adjust variable names to match actual code). Also add basic `.accessibilityLabel` on both buttons.

### P2-3: VoiceOver adjustable action direction (MainBottomSheet.swift:132-138)

**Current:** `accessibilityAdjustableAction` increment and decrement both cycle the sheet snap in the same direction.
**Fix:** Verify that increment moves to the next larger snap and decrement moves to the next smaller snap. If they are both going the same direction, swap one.

---

## Constraints

- Do NOT add new files.
- Do NOT change any public API or type signatures.
- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 32 existing tests must still pass. Add tests only if a fix changes observable behavior.
- Search for any remaining hardcoded placeholder strings (`rg -n '"Today' workspace/ios/Features/`, `rg -n 'Memory draft' workspace/ios/Features/`, `rg -n '37.5665\|126.978' workspace/ios/`).
