# Phase 4 Release Notes — 2026-04-24

Audience: internal release verification / TestFlight submission prep
Build line: R51-R60 layered onto the existing R26-R50 app line

## What Changed

### R51-R52: performance and map scalability

- R51 audited runtime hot spots, added `NSCache`-backed image caching, and reduced unnecessary SwiftUI body recomputation on core surfaces.
- R52 added distance-radius `MemoryClusterizer` behavior and dynamic annotation handling to keep dense map states usable.

### R53-R54: extension surfaces

- R53 added `TodayMemoryWidget` with small/medium/large WidgetKit presentations.
- Widget data currently remains bundle-local/sample data; App Group snapshot sharing is intentionally deferred.
- R54 added `UnfadingShareExtension` so Photos.app can hand off into the Unfading composer flow.
- Share flow supports app launch and composer entry, while shared-container file import remains a deferred follow-up.

### R55-R57: system integration

- R55 added Universal Links plus `unfading://` custom-scheme routing through `DeepLinkRouter`.
- R56 expanded App Intents and Siri Shortcuts through `UnfadingShortcutsProvider`.
- R57 added background refresh and rewind-processing scheduling via `BGTaskScheduler`.

### R58-R60: release hardening

- R58 introduced `xcstrings`-based localization and English translations alongside Korean.
- R59 completed the targeted VoiceOver and Reduce Motion hardening pass.
- R60 performed the final operator-only consolidation: launchability review refresh, session resume rewrite, TestFlight checklist authoring, archive/export script revalidation, and the requested regression rerun recording.

## Verification Snapshot

- `xcodegen generate` passed.
- `bash -n workspace/ios/scripts/archive.sh` passed.
- `plutil -lint workspace/ios/scripts/export-options.plist` passed.
- Requested R60 regression command created `.deriveddata/r60/Test-R60.xcresult` but executed `0` tests because the current sandbox could not reach `CoreSimulatorService` and could not resolve SwiftPM dependencies from GitHub.

## Test State

- Current source inventory: `217` unit + `29` UI = `246` test methods.
- Latest full green baseline still on record: `229` total / `215` passed / `14` skipped / `0` failed from `round_data_export_r1`.
- Current R60 rerun result: `xcodebuild` exit `74`, `.xcresult` status `failedToStart`, executed tests `0`.

## Deferred Operator Actions

1. Apple Developer team ID registration
2. App Store Connect app and subscription product registration
3. Entitlement capability verification in the real signing environment
4. AASA deployment for `unfading.app`
5. Supabase dashboard hardening (`HIBP`, email confirm, Apple provider Services ID)
6. Privacy manifest final review
7. App Privacy Data Collection disclosure entry
8. TestFlight tester invitation pass
9. App Store metadata completion
10. Real-device signed archive/export/upload
