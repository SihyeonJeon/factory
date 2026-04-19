# Remediation Round 6 — Sprint 3 Code Review + Visual QA Blockers

**Date:** 2026-04-13
**Source:** red_team_reviewer + visual_qa (both flagged identical B1/B2)
**Goal:** Fix 2 blockers. All tests must remain green + 2 new tests.

---

## Fix B1: Reaction Accessibility (MemoryDetailView.swift)

### Problem
Reaction buttons (lines ~107-141) have selected-state trait but no `.accessibilityHint`. Reaction count labels lack `.accessibilityValue`.

### Implementation

1. **`Features/Home/MemoryDetailView.swift`** modification
   - On each reaction chip/button, add:
     ```swift
     .accessibilityHint("이 감정으로 반응합니다")
     ```
   - On each reaction count label, add:
     ```swift
     .accessibilityValue("\(count)명이 반응했습니다")
     ```

---

## Fix B2: Camera Metadata Behavioral Tests (MemoryMapTests.swift)

### Problem
`testCameraCaptureViewExists` is a trivial existence check. `CameraCaptureView.metadata(from:)` (or `PhotoMetadataExtractor`) has 3 code paths and 0 behavioral tests.

### Implementation

1. **`Tests/MemoryMapTests.swift`** — add 2 new tests:
   - `testCameraMetadataFromMediaMetadata` — create a test image `Data` with known EXIF GPS/date properties using `CGImageDestination`, pass to `PhotoMetadataExtractor.extractMetadata(from:)`, assert coordinate and date are correctly parsed.
   - `testCameraMetadataEmptyFallback` — pass a plain PNG `Data` with no EXIF, assert `extractMetadata` returns nil coordinate and nil date.

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- Expected: 58 tests, 0 failures.
