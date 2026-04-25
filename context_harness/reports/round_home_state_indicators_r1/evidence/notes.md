# round_home_state_indicators_r1 Evidence Notes

## Defect
- Defect ID: round_home_state_indicators_r1
- User-visible failure: Home map screen had no visible state indicator showing the active category filter or the currently selected pin/cluster, making it hard for users to monitor app state at a glance.
- Target files / line ranges: `workspace/ios/Features/Home/MemoryMapHomeView.swift:74-114, 336-360, 583-602, 624-637`; `workspace/ios/Tests/UnfadingBottomSheetTests.swift:127-141`.

## Code Axis
- Reviewer: Codex Verifier fresh session (separate from Codex Implementer dispatch-1).
- Result: PASS
- Evidence:
  - A1 helper `MemoryMapHomeLayout.homeStateIndicatorText(activeCategoryName:hasSelection:)` covers all 4 states at `MemoryMapHomeView.swift:593-599` (nil → nil; nil + selection → "선택됨"; category only → "필터: <name>"; both → "필터: <name> · 선택됨"). Body computes `categoryName`/`hasSelection`/`indicatorText` at `MemoryMapHomeView.swift:74-80` and renders overlay at `MemoryMapHomeView.swift:110-114`. `HomeStateIndicatorLabel` separated as private struct at `MemoryMapHomeView.swift:624-637` to avoid Swift type-check timeout.
  - A2 clear action `clearHomeStateIndicators()` at `MemoryMapHomeView.swift:354-358` resets all three states: `selection.clearSelection()`, `selectedMapItemID = nil`, `activeCategoryId = CategoryStore.allCategoryId`. Wired into `homeStateIndicator` button action at `MemoryMapHomeView.swift:340`.
  - A3 accessibility at `MemoryMapHomeView.swift:349-351`: `.accessibilityLabel(text)`, `.accessibilityHint("두 번 탭하면 필터와 선택을 해제합니다.")`, `.accessibilityIdentifier("home-state-indicator")`. Hit-area constrained via `.contentShape(Capsule())` + `.fixedSize()` at `MemoryMapHomeView.swift:346-347` to avoid intercepting mapControls on small screens.
- Reject reason, if FAIL: n/a.

## Runtime Axis
- Device/simulator: iOS Simulator iPhone 17 Pro, iOS 26.4, device id `00FCC049-D60A-4426-8EE3-EA743B48CCF9`.
- Scenario: `xcodebuild test -derivedDataPath .deriveddata/r72 -resultBundlePath .deriveddata/r72/Test-R72.xcresult` per eval protocol.
- Result: PASS
- Screenshot/video/xcresult: `workspace/ios/.deriveddata/r72/Test-R72.xcresult`; summary `result: Passed`, `passedTests: 256`, `failedTests: 0`, `skippedTests: 18`, `totalTestCount: 274`.
- New helper tests all passed:
  - `UnfadingBottomSheetTests/test_home_state_indicator_returns_nil_when_no_state()`
  - `UnfadingBottomSheetTests/test_home_state_indicator_shows_selection_only()`
  - `UnfadingBottomSheetTests/test_home_state_indicator_shows_category_only()`
  - `UnfadingBottomSheetTests/test_home_state_indicator_shows_category_and_selection()`
- Reject reason, if FAIL: n/a.

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_home_state_indicators_r1.lock` exists with `status: active` and hashes for `spec.md`, `acceptance.md`, `eval_protocol.md`, `file_whitelist.txt`.
- Acceptance count <= 3: yes. `acceptance.md` defines A1, A2, A3 only.
- Author != verifier: yes. Implementer was a fresh Codex Implementer session (dispatch-1); verification was performed by a separate fresh Codex Verifier session (dispatch-2). Author/Verifier separation enforced.
- Result: PASS
- Whitelist scope (R63-R71 precedent): source/test/contract/evidence artifacts all valid; auto-generated lock infrastructure (`*.lock`, `*.events.jsonl`) excluded from whitelist enforcement.
- Reject reason, if FAIL: n/a.

## Handoff
- Commit/push delegated to Claude Code: yes
- Verdict: OK to handoff
- Note: evidence/notes.md was authored on Claude Code's behalf because the verifier Codex session's sandbox did not include `context_harness/` write access. Verdict and evidence cited above were produced by the verifier Codex session.
