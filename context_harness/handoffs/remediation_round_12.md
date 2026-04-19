# Remediation Round 12 — Sprint 8-A HIG Search Bar Blockers

**Date:** 2026-04-14
**Source:** HIG Guardian + Visual QA evaluation blockers
**Goal:** Fix 2 HIG tap target violations on the search bar. All 75 tests must remain green.

---

## Fix B1: Search field container below 44pt

### Problem
`UnfadingHomeView.swift` — The search HStack uses `.padding(.vertical, 10)` around a `.subheadline` icon, yielding ~35-37pt total height, below HIG 44pt minimum.

### Implementation
Add `.frame(minHeight: 44)` to the search HStack, BEFORE the `.background(...)`:

```swift
.padding(.horizontal, 12)
.padding(.vertical, 10)
.frame(minHeight: 44)   // ADD THIS
.background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
```

---

## Fix B2: Clear search button tap area ~15pt

### Problem
`UnfadingHomeView.swift` — The `xmark.circle.fill` clear button uses `.font(.subheadline)` with `.buttonStyle(.plain)` and no explicit frame. Touch target ≈ 15pt.

### Implementation
Add frame and content shape to the clear Button:

```swift
.buttonStyle(.plain)
.frame(minWidth: 44, minHeight: 44)   // ADD THIS
.contentShape(Rectangle())             // ADD THIS
.accessibilityLabel("검색어 지우기")
```

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All 75 tests must pass.
