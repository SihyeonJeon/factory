# Launchability Review — Phase 3 Final (2026-04-24)

Round: `round_phase3_final_r1`
Primary locale: Korean (`ko_KR`)
Build target: `MemoryMap`
Signing status: `DEVELOPMENT_TEAM` remains empty until an Apple Developer team is assigned.

## Integrated Scope

- Phase 1 complete: R26-R30 delivered the Unfading token reset, custom 3-tab shell, rebuilt bottom sheet, home chrome, and overlay stack.
- Phase 2 complete: R31-R35 delivered the rebuilt composer, Sprint 28 memory detail, calendar dial/day detail, rewind stories, and settings-driven group hub.
- Launch/TestFlight prep complete: R36-R39 delivered ship assets, local StoreKit paywall, launchability review, E2E/TestFlight helper scripts, and screenshot harvest support.
- Phase 3 product hardening complete: R41-R49 delivered real-data wiring, StoreKit server sync stub wiring, native Sign in with Apple client flow, realtime/offline handling, marker/detail stabilization, map themes, search, and data export.
- Final consolidation complete: R50 refreshed the release-facing docs and reran the requested regression in the current workspace-write sandbox without changing app code.

## Status Table

| Area | Status | Notes |
|---|---|---|
| Design shell + map surface | CHECK | R26-R30 shell, chrome, sheet, overlays, marker/detail surface, and theme work are integrated. |
| Composer + memory detail + calendar + rewind | CHECK | R31-R35 flows remain integrated and visible in the current codebase. |
| Local StoreKit paywall | CHECK | On-device paywall and entitlement state surfaces remain available for manual verification. |
| Server subscription sync stub | CHECK | Phase 3 added app-side sync wiring toward backend receipt/subscription reconciliation. |
| Apple Sign in client | CHECK | Native Sign in with Apple client wiring landed in-app; backend/provider setup remains external. |
| Real data / realtime / offline | CHECK | Supabase-backed data wiring, realtime incoming-memory flow, and offline queue support are present. |
| Search / map themes / export | CHECK | Search surface, theme preference flow, and JSON/photo export surfaces are integrated. |
| Archive helper | CHECK | `workspace/ios/scripts/archive.sh` passed `bash -n` on 2026-04-24. |
| Export options plist | CHECK | `workspace/ios/scripts/export-options.plist` passed `plutil -lint` on 2026-04-24. |
| Latest green baseline | CHECK | `context_harness/reports/round_data_export_r1/evidence/xcresult_summary.json` recorded `229` total tests with `215` passed / `14` skipped / `0` failed. |
| Requested final regression rerun | BLOCKED | The 2026-04-24 R50 rerun created `.deriveddata/r50/Test-R50.xcresult` but stopped before test execution with `xcodebuild` exit `74`. |
| Signed archive / TestFlight upload | DEFER | Real archive/export/upload still depends on Apple team assignment, App Store Connect product setup, and physical-device upload verification. |

## Final Test Inventory

- Current source inventory: `201` unit tests + `28` UITests = `229` test methods.
- Last known full green simulator baseline: `229` total, `215` passed, `14` skipped, `0` failed (`round_data_export_r1` evidence).
- Current R50 rerun in this sandbox: `0` executed, `.xcresult` status `failedToStart`, `xcodebuild` exit `74`.

## Known Skip List (14)

1. `SupabaseE2ETests.testSignInAndFetchProfile` — skips when `UNFADING_E2E_EMAIL/PASSWORD` are unset.
2. `SupabaseE2ETests.testCreateAndFetchGroupThenMemory` — same E2E credential gate.
3. `UnfadingUITests.testCalendarDialOpensMonthPicker` — simulator timing; verify on device.
4. `UnfadingUITests.testPlanCardVisibleInGeneralGroup` — requires future-date plan stub; verify on device.
5. `UnfadingUITests.testGroupHubFromSettings` — SwiftUI `List` row identifier flakiness in simulator.
6. `UnfadingUITests.testMemoryDetailOpensAndShowsSections` — selected-pin bootstrap deferred to marker/detail smoke path.
7. `UnfadingUITests.testMarkerClickPopulatesSheetFiltered` — MapKit annotation hitability can fail in simulator stub.
8. `UnfadingUITests.testMapBottomSheetSnapGestures` — 5pt handle swipe flakiness; device-only smoke.
9. `UnfadingUITests.testSheetCollapsedHandleIsAboveTabBar` — same simulator gesture limitation.
10. `UnfadingUITests.testSheetExpandedBackButtonReturnsToDefault` — same simulator gesture limitation.
11. `UnfadingUITests.testSheetScrollDoesNotCollapseWhenNotAtTop` — same simulator gesture limitation.
12. `UnfadingUITests.testCategoryEditorOpensFromFilterPlus` — horizontal scroll hit-point issue in simulator.
13. `UnfadingUITests.testRewindFromHomeCuration` — navigation-wrapped query flakiness in simulator.
14. `UnfadingUITests.testRewindStoriesOpensAndAdvances` — story stub can fail to open in simulator.

## R50 Verification Snapshot

- Requested command executed on 2026-04-24:

```bash
cd /Users/jeonsihyeon/factory/workspace/ios
xcodegen generate
xcodebuild test \
  -project MemoryMap.xcodeproj \
  -scheme MemoryMap \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath .deriveddata/r50 \
  -resultBundlePath .deriveddata/r50/Test-R50.xcresult
```

- Observed blockers in this sandbox:
  - `CoreSimulatorService connection became invalid`
  - `Could not resolve package dependencies`
  - multiple `fatal: unable to access 'https://github.com/...': Could not resolve host: github.com`
- Result bundle exists: `workspace/ios/.deriveddata/r50/Test-R50.xcresult`
- Result status: `failedToStart`
- Executed tests: `0`

## Remaining Deferred

| Item | Owner | Reason |
|---|---|---|
| App Store Connect product registration | Operator / owner action | App record, subscriptions/products, privacy answers, screenshots, support/privacy URLs are not registered yet. |
| Apple Developer team ID | Operator / owner action | `DEVELOPMENT_TEAM` is still unset, so signed archive/export cannot be completed. |
| Supabase HIBP leaked-password toggle | Operator / owner action | Dashboard configuration item, not an in-repo code change. |
| Real-device TestFlight upload | Operator / owner action | Requires a signed archive/export plus actual App Store Connect upload from a provisioned environment. |

## Evidence

- Phase 3 final evidence: `context_harness/reports/phase3_final/evidence/`
- R50 test log: `context_harness/reports/phase3_final/evidence/xcodebuild_test_r50.log`
- R50 summary: `context_harness/reports/phase3_final/evidence/xcresult_summary.json`
- Archive helper: `workspace/ios/scripts/archive.sh`
- Export plist: `workspace/ios/scripts/export-options.plist`
