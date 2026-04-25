# round_tabbar_compact_height_r1 Evidence Notes

## Defect
- Defect ID: round_tabbar_compact_height_r1
- User-visible failure: Custom bottom tab bar was 83pt tall and visually floated too high, reducing map/sheet space.
- Target files / line ranges: `workspace/ios/App/UnfadingTabShell.swift:277-344`; `workspace/ios/Tests/UnfadingTabBarTests.swift:1-14`; dependent reads in `workspace/ios/Features/Home/MemoryMapHomeView.swift:109-112,529-532` and `workspace/ios/Shared/UnfadingBottomSheet.swift:174-179`.

## Code Axis
- Reviewer: Codex Verifier fresh session, separate from Codex Implementer dispatch-1.
- Result: PASS
- Evidence:
  - A1 compact height + 44pt target: `UnfadingTabBar.height` is `64` at `UnfadingTabShell.swift:278`, below 80 and below old 83. `hitTargetHeight` is `44` at `UnfadingTabShell.swift:279`; each tab label stack applies `.frame(height: Self.hitTargetHeight)` and `.contentShape(Rectangle())` at `UnfadingTabShell.swift:335-337`.
  - A2 bottom alignment / top padding removal: tab row applies `.frame(height: Self.height, alignment: .bottom)` at `UnfadingTabShell.swift:301`; there is no added top padding in the tab button stack at `UnfadingTabShell.swift:315-337`.
  - A3 dependent layout reads shared height: `MemoryMapHomeView` passes `tabBarHeight: UnfadingTabBar.height` into `UnfadingBottomSheet` at `MemoryMapHomeView.swift:109-112`; `sheetTopY` calculates available height and return position using `UnfadingTabBar.height` at `MemoryMapHomeView.swift:529-532`. `UnfadingBottomSheet` consumes `tabBarHeight` in `availableHeight` and `bottomInset` at `UnfadingBottomSheet.swift:174-179`.
  - Regression tests added: `test_tab_bar_height_is_compact_but_not_cramped` asserts `< 80` and `>= 56` at `UnfadingTabBarTests.swift:6-9`; `test_tab_button_hit_target_meets_minimum` asserts `>= 44` at `UnfadingTabBarTests.swift:11-13`.
- Reject reason, if FAIL: N/A

## Runtime Axis
- Device/simulator: iOS Simulator, iPhone 17 Pro, iOS 26.4, xcresult at `workspace/ios/.deriveddata/r65/Test-R65.xcresult`.
- Scenario: `xcodebuild test -derivedDataPath .deriveddata/r65 -resultBundlePath .deriveddata/r65/Test-R65.xcresult` per eval protocol.
- Result: PASS
- Screenshot/video/xcresult:
  - xcresult summary: `result: Passed`, `totalTestCount: 256`, `passedTests: 238`, `failedTests: 0`, `skippedTests: 18`, `expectedFailures: 0`.
  - Test tree: `UnfadingTabBarTests/test_tab_bar_height_is_compact_but_not_cramped()` result `Passed`.
  - Test tree: `UnfadingTabBarTests/test_tab_button_hit_target_meets_minimum()` result `Passed`.
- Reject reason, if FAIL: N/A

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_tabbar_compact_height_r1.lock` exists with `round_id: round_tabbar_compact_height_r1`, `schema_version: 2`, status `active`, and hashes for `spec.md`, `acceptance.md`, `eval_protocol.md`, and `file_whitelist.txt`.
- Acceptance count <= 3: yes. `acceptance.md` contains A1, A2, A3 only, consistent with `spec.md` and `eval_protocol.md`.
- Author != verifier: yes. Eval protocol states Author is Codex Implementer fresh session dispatch-1 and Verifier is separate Codex Verifier fresh session dispatch-2; this evidence was written by the fresh verifier session.
- Result: PASS
- Reject reason, if FAIL: N/A
- Whitelist scope: PASS. Source/contract whitelist covers `UnfadingTabShell.swift`, `UnfadingTabBarTests.swift`, and round contract/evidence artifacts. Per R63/R64 precedent and user scope, auto-generated lock infrastructure (`context_harness/operator/locks/round_tabbar_compact_height_r1.lock`, `.events.jsonl`) is excluded from whitelist enforcement.

## Handoff
- Commit/push delegated to Claude Code: yes
- Verdict: OK to handoff
