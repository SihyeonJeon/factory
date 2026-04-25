# round_button_placement_audit_r1 Evidence Notes

## Defect
- Defect ID: round_button_placement_audit_r1
- User-visible failure: Home action buttons needed placement audit by task ownership/frequency; icon-only controls also needed explicit inventory and 44pt hit-target verification.
- Target files / line ranges: `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 116-129, 565-653, 802-818, 836-884; `workspace/ios/Features/Home/ComposeFAB.swift` lines 3-27; `workspace/ios/Tests/UnfadingBottomSheetTests.swift` lines 143-175.

## Code Axis
- Reviewer: Codex Verifier fresh session; not the implementing author.
- Result: PASS
- Evidence:
  - A1 inventory is implemented in `MemoryMapHomeView.swift`: `HomeActionZone` enum lines 629-634, `HomeAction` struct lines 636-641, and `HomeActionInventory.all` seven entries lines 643-652.
  - Inventory identifiers cross-reference to real accessibility identifiers:
    - `home-top-chrome-group-button`: inventory line 645, actual line 714.
    - `home-top-chrome-search-button`: inventory line 646, actual line 726.
    - `home-map-control-current-location`: inventory line 647, actual line 840.
    - `home-map-control-reset-orientation`: inventory line 648, actual line 847.
    - `home-fab`: inventory line 649, actual `ComposeFAB.swift` line 26.
    - `home-filter-add-category`: inventory line 650, actual line 818.
    - `home-state-indicator`: inventory line 651, actual line 354.
  - A2 category edit `+` keeps secondary visual styling with primary opacity 0.66 and dashed circle stroke at lines 802-813, and adds `.accessibilityHint("두 번 탭하면 새 카테고리를 추가합니다.")` at line 817.
  - A3 hit-target layout is consistent: `mapControlsHitTargetSize: CGFloat = 44` at line 580, `mapControlsStackHeight = (mapControlsHitTargetSize * 2) + mapControlsSpacing` at line 582, parent map controls frame uses width/height based on hit target and stack height at lines 116-120, and `MapControlButton` applies `.frame(minWidth: ..., minHeight: ...)` plus `.contentShape(Rectangle())` at lines 877-881.
  - New unit tests are present at `UnfadingBottomSheetTests.swift` lines 143-175: inventory count, non-empty identifiers, minimum hit target, zone coverage, and stack-height invariant.
- Reject reason, if FAIL: n/a.

## Runtime Axis
- Device/simulator: iPhone 17 Pro simulator, iOS 26.4, xcresult at `workspace/ios/.deriveddata/r73/Test-R73.xcresult`.
- Scenario: `xcodebuild test -derivedDataPath .deriveddata/r73` result bundle verification for full suite plus new inventory/layout tests.
- Result: PASS
- Screenshot/video/xcresult:
  - xcresult summary: result `Passed`, total 279, passed 261, failed 0, skipped 18, expected failures 0.
  - New tests individually passed:
    - `test_home_action_inventory_has_at_least_seven_entries()` Passed.
    - `test_home_action_inventory_identifiers_non_empty()` Passed.
    - `test_home_action_inventory_meets_hit_target_minimum()` Passed.
    - `test_home_action_inventory_covers_all_zones()` Passed.
    - `test_map_controls_stack_height_uses_hit_target_not_visual_size()` Passed.
- Reject reason, if FAIL: n/a.

## Process Axis
- Contract locked: yes; `context_harness/operator/locks/round_button_placement_audit_r1.lock` exists and status is `active`.
- Acceptance count <= 3: yes; `acceptance.md` has A1, A2, A3.
- Author != verifier: yes; eval protocol names Author as Codex Implementer fresh session and Verifier as separate Codex Verifier fresh session; this verification was performed in a fresh verifier session.
- Result: PASS
- Reject reason, if FAIL: n/a.
- Whitelist scope: PASS. `file_whitelist.txt` contains source code, test code, contract files, and evidence report. Lock infrastructure (`*.lock`, `*.events.jsonl`) is not included in the whitelist, matching the R63-R72 precedent while still allowing lock existence to be read for process verification.

## Handoff
- Commit/push delegated to Claude Code: yes.
- Three-axis close verdict: Code PASS, Runtime PASS, Process PASS.
- OK to handoff.
