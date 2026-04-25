# round_sheet_true_fullscreen_r1 Evidence Notes

## Defect
- Defect ID: round_sheet_true_fullscreen_r1
- User-visible failure: expanded bottom sheet did not occupy true fullscreen near the top safe area / Dynamic Island.
- Target files / line ranges: `workspace/ios/Shared/UnfadingBottomSheet.swift:70-260`, `workspace/ios/Tests/UnfadingBottomSheetTests.swift:20-50`

## Code Axis
- Reviewer: Codex Verifier fresh session; Author != Verifier per eval protocol.
- Result: PASS
- Evidence:
  - A1 PASS: `BottomSheetDragResolution.availableHeight(...)` returns `max(screenHeight + topSafeArea, 1)` for `snap == .expanded` at `UnfadingBottomSheet.swift:78-86`; non-expanded returns `max(screenHeight - tabBarHeight, 1)` at `UnfadingBottomSheet.swift:88`.
  - A1 PASS: `body` calls the helper with `screenHeight`, `tabBarHeight`, `proxy.safeAreaInsets.top`, and `snap` at `UnfadingBottomSheet.swift:187-195`, then derives `currentSnapHeight` / `liveHeight` from that available height at `UnfadingBottomSheet.swift:197-198`.
  - A2 PASS: expanded background applies `.ignoresSafeArea(.container, edges: .top)` at `UnfadingBottomSheet.swift:242-246`.
  - A3 PASS: collapsed/default retain `screenHeight - tabBarHeight`; tests assert expanded `800 + 59 == 859` at `UnfadingBottomSheetTests.swift:25-35` and non-expanded `800 - 64 == 736` at `UnfadingBottomSheetTests.swift:37-47`.
- Reject reason, if FAIL: n/a

## Runtime Axis
- Device/simulator: iPhone 17 Pro iOS Simulator 26.4, result bundle `workspace/ios/.deriveddata/r68/Test-R68.xcresult`
- Scenario: `xcodebuild test -derivedDataPath .deriveddata/r68` result bundle review, including new bottom sheet helper tests.
- Result: PASS
- Screenshot/video/xcresult:
  - xcresult summary: `result = Passed`, `totalTestCount = 262`, `passedTests = 244`, `failedTests = 0`, `skippedTests = 18`.
  - `test_available_height_uses_full_screen_plus_top_inset_when_expanded()` result: `Passed`.
  - `test_available_height_subtracts_tab_bar_when_not_expanded()` result: `Passed`.
- Reject reason, if FAIL: n/a

## Process Axis
- Contract locked: yes; `context_harness/operator/locks/round_sheet_true_fullscreen_r1.lock` exists with `status: active` and hashes for base contract files.
- Acceptance count <= 3: yes; `acceptance.md` has A1, A2, A3 only.
- Author != verifier: yes; eval protocol states Author is Codex Implementer fresh session and Verifier is separate Codex Verifier fresh session; this verification is a fresh Codex Verifier session.
- Result: PASS
- Evidence:
  - `spec.md`, `acceptance.md`, and `eval_protocol.md` consistently require expanded full-height calculation, expanded top safe-area background coverage, and non-expanded tabbar avoidance.
  - `file_whitelist.txt` includes the source/test and contract artifacts for this round; lock infrastructure (`*.lock`, `*.events.jsonl`) is not listed.
- Reject reason, if FAIL: n/a

## 3-Axis Summary
| Axis | Result |
|---|---|
| Code | PASS |
| Runtime | PASS |
| Process | PASS |

## Handoff
- Commit/push delegated to Claude Code: yes
- OK to handoff.
