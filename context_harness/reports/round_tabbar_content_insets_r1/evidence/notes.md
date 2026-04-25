# round_tabbar_content_insets_r1 Evidence Notes

## Defect
- Defect ID: round_tabbar_content_insets_r1
- User-visible failure: Main content, overlays, and non-map tabs could be obscured by the compact custom tab bar because tab bar visual height and reserved bottom inset were not modeled consistently.
- Target files / line ranges: `workspace/ios/App/UnfadingTabShell.swift` lines 113-137 and 187-210; `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 536-545; `workspace/ios/Tests/UnfadingBottomSheetTests.swift` lines 65-68.

## Code Axis
- Reviewer: Codex Verifier fresh session.
- Result: PASS
- Evidence:
  - A1 PASS: `MemoryMapHomeLayout.tabBarReserve(safeBottom:)` exists at `MemoryMapHomeView.swift:536-538` and returns `UnfadingTabBar.height + safeBottom`. `UnfadingTabShell.swift:133-137` applies `MemoryMapHomeLayout.tabBarReserve(safeBottom: proxy.safeAreaInsets.bottom) + UnfadingTheme.Spacing.sm` to the offline queue/incoming toast overlay stack.
  - A2 PASS: helper regression test exists at `UnfadingBottomSheetTests.swift:65-68`. `MemoryMapHomeLayout.sheetTopY` reuses the helper at `MemoryMapHomeView.swift:540-545`, with collapsed clearance preserved via `+ clearance`.
  - A3 PASS: calendar branch applies `.safeAreaInset(edge: .bottom, spacing: 0)` at `UnfadingTabShell.swift:201-205`; settings branch applies the same at `UnfadingTabShell.swift:206-210`. Map branch remains the direct `MemoryMapHomeView(...)` branch at `UnfadingTabShell.swift:190-200` with no added safe-area inset, preserving the full-bleed map behavior.
- Reject reason, if FAIL: n/a

## Runtime Axis
- Device/simulator: iPhone 17 Pro iOS 26.4 simulator (`00FCC049-D60A-4426-8EE3-EA743B48CCF9`), from `.deriveddata/r70/Test-R70.xcresult`.
- Scenario: `xcodebuild test -derivedDataPath .deriveddata/r70` result bundle inspection via `xcrun xcresulttool`.
- Result: PASS
- Screenshot/video/xcresult: `workspace/ios/.deriveddata/r70/Test-R70.xcresult` summary reports `result: Passed`, `totalTestCount: 265`, `passedTests: 247`, `failedTests: 0`, `skippedTests: 18`. New `UnfadingBottomSheetTests/test_tab_bar_reserve_equals_height_plus_safe_bottom()` is present in the xcresult and reports `result: Passed`.
- Reject reason, if FAIL: n/a

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_tabbar_content_insets_r1.lock` exists with `round_id` at lines 2, `status: active` at line 5, and hashes for `spec.md`, `file_whitelist.txt`, `acceptance.md`, and `eval_protocol.md` at lines 18-23.
- Acceptance count <= 3: yes. `spec.md:11-14` lists 3 acceptance items and `acceptance.md:3-10` defines A1-A3 only.
- Author != verifier: yes. `eval_protocol.md:3-6` specifies Author as Codex Implementer fresh session and Verifier as separate Codex Verifier fresh session; this notes file was written in a fresh Codex Verifier session.
- Result: PASS
- Evidence:
  - Contract consistency PASS: `spec.md:11-19`, `acceptance.md:3-10`, and `eval_protocol.md:8-23` align around the same helper, overlay padding, non-map reserve, runtime xcresult, and process checks.
  - Whitelist scope PASS under the R63-R69 precedent supplied by the user: `file_whitelist.txt:1-11` covers source code, test code, contract files, and the evidence report path. Lock infrastructure (`*.lock`, `*.events.jsonl`) is excluded from whitelist enforcement.
- Reject reason, if FAIL: n/a

## Axis Summary
| Axis | Result |
|------|--------|
| Code | PASS |
| Runtime | PASS |
| Process | PASS |

## Handoff
- Commit/push delegated to Claude Code: yes
- Close verdict: OK to handoff
