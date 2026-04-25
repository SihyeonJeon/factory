# round_home_chrome_collision_r1 Evidence Notes

## Defect
- Defect ID: `round_home_chrome_collision_r1`
- User-visible failure: Home top chrome/search/filter/map controls could collide with Dynamic Island/safe area, bottom sheet, FAB, or each other in collapsed/default home layout.
- Target files / line ranges:
  - `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 60-115, 524-559.
  - `workspace/ios/Tests/UnfadingBottomSheetTests.swift` lines 70-125.
  - Contract files under `context_harness/operator/contracts/round_home_chrome_collision_r1/`.

## Code Axis
- Reviewer: Codex Verifier fresh session.
- Result: PASS
- Evidence:
  - A1 constants/helpers present in `MemoryMapHomeLayout`: `topChromeMargin` line 528, `topChromeBottomToFilterGap` line 532, `filterToMapControlsMinGap` line 552, `topChromeY(safeTop:)` lines 544-546, `filterChipY(safeTop:)` lines 548-550, `mapControlsCenterY(safeTop:sheetTop:)` lines 554-559.
  - A2 body uses helpers for positioned chrome: `topChrome` `.position(y:)` uses `MemoryMapHomeLayout.topChromeY(safeTop:)` lines 85-89; `filterRow` uses `filterChipY(safeTop:)` lines 95-99; `mapControls` uses `mapControlsCenterY(safeTop:sheetTop:)` lines 105-111.
  - A3 collision-free unit tests present: `test_top_chrome_y_clears_dynamic_island` lines 70-72; `test_filter_chip_y_below_top_chrome_with_gap` lines 74-80; `test_filter_bottom_above_default_sheet_top` lines 82-91; `test_map_controls_clear_filter_row_on_small_screens` lines 93-109; `test_map_controls_use_preferred_center_on_large_screens` lines 111-125.
- Reject reason, if FAIL: none.

## Runtime Axis
- Device/simulator: iPhone 17 Pro iOS Simulator, iOS 26.4, arm64.
- Scenario: `xcodebuild test` result bundle at `workspace/ios/.deriveddata/r71/Test-R71.xcresult`.
- Result: PASS
- Screenshot/video/xcresult:
  - xcresult summary: `result = Passed`, `totalTestCount = 270`, `passedTests = 252`, `failedTests = 0`, `skippedTests = 18`, `expectedFailures = 0`.
  - Named tests passed in xcresult:
    - `test_top_chrome_y_clears_dynamic_island()`: Passed.
    - `test_filter_chip_y_below_top_chrome_with_gap()`: Passed.
    - `test_filter_bottom_above_default_sheet_top()`: Passed.
    - `test_map_controls_clear_filter_row_on_small_screens()`: Passed.
    - `test_map_controls_use_preferred_center_on_large_screens()`: Passed.
- Reject reason, if FAIL: none.

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_home_chrome_collision_r1.lock` exists with `status: active`, `schema_version: 2`, and hashes for base contract files.
- Acceptance count <= 3: yes. `spec.md` lines 11-14 list 3 acceptance items; `acceptance.md` narrows to A1-A3. A3 in `acceptance.md` covers 3 listed tests, and the implementation additionally covers the `spec.md` A3 map-controls collision surface through same whitelisted source/test files.
- Author != verifier: yes. `eval_protocol.md` lines 3-6 requires Author: Codex Implementer fresh session, Verifier: separate Codex Verifier fresh session, Author != Verifier. This note was written by a fresh Codex Verifier session.
- Whitelist scope: PASS. `file_whitelist.txt` contains source code, test code, contract files, and evidence report only. Lock infrastructure (`*.lock`, `*.events.jsonl`) is excluded from whitelist scope per R63-R70 precedent.
- Result: PASS
- Reject reason, if FAIL: none.

## 3-Axis Close Table
| Axis | Result |
|------|--------|
| Code | PASS |
| Runtime | PASS |
| Process | PASS |

## Handoff
- Commit/push delegated to Claude Code: yes.
- Close verdict: OK to handoff.
