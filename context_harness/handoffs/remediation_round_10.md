# Remediation Round 10 — Sprint 7 Unanimous Blocker + Advisories

**Date:** 2026-04-13
**Source:** 3/3 evaluators flagged B1 (unanimous). 3 advisories from HIG + Visual QA.
**Goal:** Fix 1 blocker + 3 advisories. All 75 tests must remain green.

---

## Fix B1: Hardcoded font in MemoryPinMarker (UNANIMOUS — 3/3 evaluators)

### Problem
`MemoryPinMarker.swift:89` uses `.system(size: 19, weight: .semibold, design: .rounded)` for `handDrawn` pack. Dynamic Type users see no scaling.

### Implementation
- Replace `.system(size: 19, weight: .semibold, design: .rounded)` with `.title3.weight(.semibold)`

---

## Fix A1: MapThemePickerView VoiceOver state (Advisory)

### Problem
`MapThemePickerView.swift:54` — `.accessibilityLabel` present but no `.accessibilityValue` or `.accessibilityHint`. VoiceOver cannot detect selection state or premium lock.

### Implementation
- After `.accessibilityLabel(...)` on each theme button, add:
  ```swift
  .accessibilityValue(selectedTheme == theme ? "Selected" : "Not selected")
  .accessibilityHint(theme.isPremium && !subscriptionStore.isPremium ? "Requires Premium" : "")
  ```

---

## Fix A2: PinIconPackPickerView VoiceOver state (Advisory)

### Problem
`PinIconPackPickerView.swift:58` — identical to A1.

### Implementation
- Same fix as A1 on each pin pack button

---

## Fix A3: PremiumUpgradeView button tap targets (Advisory)

### Problem
`PremiumUpgradeView.swift:21,29` — Upgrade/Restore buttons intrinsic height ~34pt, below HIG 44pt minimum.

### Implementation
- Add `.frame(maxWidth: .infinity, minHeight: 44)` to both Upgrade and Restore buttons

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 75 tests must pass.
