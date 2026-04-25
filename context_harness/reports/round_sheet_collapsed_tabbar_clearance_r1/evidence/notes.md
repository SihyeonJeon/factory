# round_sheet_collapsed_tabbar_clearance_r1 Evidence Notes

## Defect
- Defect ID: round_sheet_collapsed_tabbar_clearance_r1
- User-visible failure: collapsed bottom sheet could hide under or overlap the bottom tab bar, making the handle/summary visually unreliable.
- Target files / line ranges: `workspace/ios/Shared/UnfadingBottomSheet.swift` lines 190-200 and 271; `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 536-541; `workspace/ios/Tests/UnfadingBottomSheetTests.swift` lines 49-62.

## Code Axis
- Reviewer: Codex Verifier fresh session, separate from the Codex Implementer author session required by `eval_protocol.md`.
- Result: PASS
- Evidence:
  - A1 collapsed clearance: `UnfadingBottomSheet.swift` lines 190-198 compute `availableHeight` from `screenHeight`, `tabBarHeight`, `topSafeArea`, and `snap`; line 196 sets `clearance` to `8` only for `.collapsed`; line 197 computes `bottomInset = tabBarHeight + proxy.safeAreaInsets.bottom + clearance`; line 271 applies `.padding(.bottom, bottomInset)`.
  - A2 same sheetTopY model: `MemoryMapHomeView.swift` lines 536-541 use `availableHeight = max(screenHeight - UnfadingTabBar.height, 1)`, `sheetHeight = availableHeight * snap.fraction`, `clearance = 8` only for `.collapsed`, `bottomInset = UnfadingTabBar.height + safeBottom + clearance`, and return `screenHeight - bottomInset - sheetHeight`.
  - A3 tests added: `UnfadingBottomSheetTests.swift` lines 49-55 assert collapsed bottom edge is `UnfadingTabBar.height + 34 + 8` from screen bottom; lines 57-62 assert default snap has no extra clearance.
- Reject reason, if FAIL: n/a

## Runtime Axis
- Device/simulator: iOS Simulator `iPhone 17 Pro`, device id `00FCC049-D60A-4426-8EE3-EA743B48CCF9`, iOS 26.4 (`23E244`), from `workspace/ios/.deriveddata/r69/Test-R69.xcresult`.
- Scenario: `xcrun xcresulttool get test-results summary --path workspace/ios/.deriveddata/r69/Test-R69.xcresult` and targeted test tree review.
- Result: PASS
- Screenshot/video/xcresult: `workspace/ios/.deriveddata/r69/Test-R69.xcresult`; result `Passed`; totalTestCount `264`; passedTests `246`; failedTests `0`; skippedTests `18`; expectedFailures `0`.
- New test evidence: `UnfadingBottomSheetTests/test_collapsed_sheet_clears_tab_bar_with_8pt_padding()` result `Passed`; `UnfadingBottomSheetTests/test_default_sheet_has_no_extra_clearance()` result `Passed`.
- Reject reason, if FAIL: n/a

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_sheet_collapsed_tabbar_clearance_r1.lock` exists with `round_id` `round_sheet_collapsed_tabbar_clearance_r1`, status `active`, schema_version `2`, and matching locked hashes for `spec.md`, `file_whitelist.txt`, `acceptance.md`, and `eval_protocol.md`.
- Acceptance count <= 3: yes. `acceptance.md` defines A1, A2, and A3 only.
- Author != verifier: yes. `eval_protocol.md` explicitly names Author as a Codex Implementer fresh session and Verifier as a separate Codex Verifier fresh session; this evidence note was written by the fresh verifier session.
- Result: PASS
- Reject reason, if FAIL: n/a
- Contract consistency: PASS. `spec.md`, `acceptance.md`, and `eval_protocol.md` consistently require collapsed 8pt tabbar clearance, unified `sheetTopY`/body calculation model, and a unit test for collapsed/default clearance.
- File whitelist check: PASS. Whitelist scope (R63-R68 precedent): source + test + contract + evidence artifacts all valid; only auto-generated lock infrastructure excluded. `file_whitelist.txt` includes the modified source files, the modified test source, the round contract artifacts, and `context_harness/reports/round_sheet_collapsed_tabbar_clearance_r1/evidence/notes.md`. The lock file and lock events file are auto-generated harness infrastructure and are outside whitelist scope.

## Handoff
- Commit/push delegated to Claude Code: yes
