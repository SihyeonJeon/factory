# eval_protocol — round_map_redesign_r1

## Inputs (read-only, hashed in contract_capture)
- `docs/design-docs/unfading_design/Unfading Prototype.html`
- `docs/design-docs/deepsight_tokens.md`
- `docs/design-docs/deepsight_gap_analysis.md`
- Pre-round `MemoryMapHomeView.swift`, `MemorySummaryCard.swift`

## Evidence capture steps (Claude Code)
1. Compute SHA for every new + modified file.
2. Build: `xcodegen generate` → `xcodebuild build` → `xcodebuild test`; capture log.
3. Boot iPhone 17 sim (UDID `00FCC049-D60A-4426-8EE3-EA743B48CCF9`), install `MemoryMap.app`, launch.
4. Screenshot: default state at Map tab → `screenshots/01_map_default.png`.
5. If pin selection is triggered (programmatically via `MemorySelectionState.select(_:)` in preview wrapper OR via XCUITest tap): capture `screenshots/02_map_pin_selected.png`; if not automated, note in evidence.
6. Run grep lint:
   - Forbidden colors (exclude `UnfadingTheme.swift`)
   - English literals in touched view Text/Label/accessibility
7. Count reusable-module references (production + test) for `UnfadingBottomSheet`, `UnfadingFilterChip`, `MemorySelectionState`.
8. Record all observations in `contract_capture.md` (factual only; no PASS/BLOCKER language).

## Verdict step (Codex)
Writes `verdict.md` with PASS/BLOCKER/ADVISORY per acceptance criterion, citing evidence sections.

## Exceptions
Pin-selection runtime screenshot may be deferred if `xcrun simctl` cannot drive tap programmatically; test-level behavioral assertions cover selection state.
