# Evidence — round_navigation_r1

**Capture protocol:** `context_harness/operator/contracts/round_navigation_r1/eval_protocol.md`
**Timestamp:** 2026-04-23T01:15Z

## Implementation file hashes

| File | SHA-256 |
|---|---|
| `workspace/ios/App/RootTabView.swift` (5-tab rewrite + compose interceptor) | `sha256:7c0c0cb46ccaf9af8c076855a0ceae141c63bcdb216b67370c97bccefbc01c94` |
| `workspace/ios/Features/Calendar/CalendarView.swift` (new stub) | `sha256:8aa5655069903b0264207bcd6c08dd42c706a983bf42a4ac45b26cb2c7b065ca` |
| `workspace/ios/Features/Settings/SettingsView.swift` (new stub + 그룹 관리 row) | `sha256:b82edeb64f7e54aa8a277d9bef7cd64832d7f80ac8d2263bd19e4dec9db02cbf` |
| `workspace/ios/Shared/UnfadingLocalized.swift` (Tab/Accessibility/Calendar/Settings additions) | `sha256:cbbc4a9028716420c62a86ad88b135af66e3187b9444d46dd8b9240168266229` |
| `workspace/ios/Tests/RootNavigationTests.swift` (new test file, 6 tests) | `sha256:96e929a5ecfe48e9a8b8afe590b3afb3c257e4a5005dd789d85befc9372a9589` |

## Test run

- Command: `xcodebuild -project workspace/ios/MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' test`
- Exit code: 0
- Log: `context_harness/reports/round_navigation_r1/evidence/xcode_test.log` sha256 `726f03078066bea9f7faa84f1fd0bd83511957263a38594b4437ac3989ec8dc1`
- Test count: **34** (baseline 28 + 6 new in RootNavigationTests)
- Log terminal line: `** TEST SUCCEEDED **`

## Runtime capture

- Simulator: `iPhone 17` UDID `00FCC049-D60A-4426-8EE3-EA743B48CCF9`
- Bundle: `com.jeonsihyeon.memorymap`
- Screenshot at Map (default) tab: `context_harness/reports/round_navigation_r1/evidence/screenshots/01_map_default.png` sha256 `3bec0945d72589902e4e1df747ebcbcc592aefd0e94311a42239225247fe034c`

Observations from the Map screenshot (factual only):
- Bottom tab bar shows 5 tabs in left-to-right order.
- Tab labels visible: "지도", "캘린더", "추억", "리와인드", "설정".
- Map tint and selected tab tint appear coral-pink (matches `UnfadingTheme.Color.primary`).
- Summary card visible at bottom uses warm cream/sheet fill with Korean content ("오늘의 리와인드", "상수 루프톱 저녁", body text, filter chips 기쁨/밤 나들이/사진 모음).
- Map pins visible in map area.

Limitations documented:
- Per-tab content screenshots (Calendar stub, Settings stub, Rewind, Composer fullScreen) were not auto-captured because `xcrun simctl` lacks a programmatic tap command. XCUITest-based tour capture is deferred to R14 `round_launchability_r1`.
- Main evidence of 5-tab runtime correctness: the Map screenshot itself shows all 5 tab labels in the tab bar.

## Codex code review cycle

- Codex R-round3-codereview transcript saved at `operator/codex_transcripts/codex_r3_codereview.log`.
- Codex identified **1 blocker + 4 advisories**:
  - Blocker: `.font(.system(size: 56, weight: .light))` in `CalendarView.swift` violates Dynamic Type discipline.
  - Advisories: make `RootTabView.Tab` `CaseIterable` with `rootOrder`; extract compose intercept to a testable reducer later; replace Settings interim groups row in R10; prune deprecated `UnfadingLocalized.Tab.groups` when no callers remain.
- Revisions applied in same round:
  - Replaced `.system(size: 56)` with `.font(.largeTitle.weight(.light)).imageScale(.large)`.
  - Made `RootTabView.Tab` `CaseIterable` and added `rootOrder` canonical order.
  - Updated `test_tab_order_matches_deepsight_plan` to assert against `rootOrder` + cross-check with `allCases`.
- Re-built and re-tested after revisions: **34/34 PASS**. Codex recommended "close after fixing the hardcoded font"; both the font fix and the advisory #1 test refinement landed.

## Acceptance grep results

- Forbidden Color patterns (`Color\.(accentColor|white|black)` | `Color\\(red:`) in touched Swift files: **empty**.
- English user-facing literals in Text/Label/accessibility in touched views: **empty**.
- Reusable-module import use (from R2 foundation): `UnfadingTheme` and `UnfadingLocalized` referenced by every new R3 file.
- R3 adds a new Group Hub entrypoint; Groups top-level tab removed. `UnfadingLocalized.Tab.groups` retained as deprecated value (callers will be pruned when R10 replaces Settings groups row).

## Capture exceptions

None.
