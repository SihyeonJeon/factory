# Remediation Round 11 — Sprint 8-A HIG Blockers

**Date:** 2026-04-13
**Source:** HIG Guardian + Visual QA evaluation blockers
**Goal:** Fix 3 HIG tap target violations. All 75 tests must remain green.

---

## Fix B1: Cluster button 42→44pt

### Problem
`UnfadingHomeView.swift:164` — cluster button uses `.frame(width: 42, height: 42)`, below HIG 44pt minimum.

### Implementation
- Change `.frame(width: 42, height: 42)` to `.frame(width: 44, height: 44)`

---

## Fix B2: Filter chips missing minHeight

### Problem
`UnfadingHomeView.swift:464–483` — time filter chips use only `padding(.vertical, 8)` with `.footnote` font. Effective height ≈ 29pt, below HIG 44pt minimum.

### Implementation
- Add `.frame(minHeight: 44)` to each filter chip button or its label content

---

## Fix B3: Minimal pin 40→44pt

### Problem
`MemoryPinMarker.swift` — `minimal` pack pin size returns 40, below HIG 44pt minimum.

### Implementation
- Find the case that returns `40` for minimal pack and change to `return 44`

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All 75 tests must pass.
