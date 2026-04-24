# Phase 4 Final Evidence Notes

## Scope

- Final operator-only consolidation for R26-R60 plus the feedback integration stream.
- No source-code edits.
- Verification limited to script/plist validation and the requested R60 regression execution.

## Commands Run

- `xcodegen generate` — passed.
- `bash -n workspace/ios/scripts/archive.sh` — passed.
- `plutil -lint workspace/ios/scripts/export-options.plist` — passed.
- Requested test command executed for `.deriveddata/r60/Test-R60.xcresult`.

## R60 Regression Result

- Current source inventory: `217` unit + `29` UITest = `246` test methods.
- Latest historical full green baseline: `229` total / `215` passed / `14` skipped / `0` failed (`round_data_export_r1`).
- Current rerun executed tests: `0`.
- `.xcresult` status: `failedToStart`.
- `xcodebuild` exit: `74`.
- Primary blockers:
  - `CoreSimulatorService connection became invalid`
  - `Unable to discover any Simulator runtimes`
  - `Could not resolve package dependencies`
  - `fatal: unable to access 'https://github.com/...': Could not resolve host: github.com`

## Deferred Operator Actions

1. Apple Developer team ID registration
2. App Store Connect app and subscription product registration
3. Entitlement capability verification in the signing environment
4. AASA deployment for `unfading.app`
5. Supabase dashboard hardening (`HIBP`, email confirm, Apple provider Services ID)
6. Privacy manifest final review
7. App Privacy Data Collection disclosure entry
8. TestFlight tester invitation pass
9. App Store metadata completion
10. Real-device signed archive/export/upload
