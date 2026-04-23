# R24 E2E And TestFlight Evidence Notes

## Deferred User Actions

- Supabase Dashboard -> Auth -> Policies -> enable HIBP leaked-password protection.
- Apple Developer enrollment -> obtain the Apple team ID required by `scripts/archive.sh <TEAM_ID>`.
- App Store Connect -> create the app record, subscription products, privacy answers, screenshots, support URL, and privacy policy URL.
- Replace placeholder AppIcon and launch art with professional branded assets.
- Create localized Korean and English App Store metadata.
- Run the first signed TestFlight archive and upload after signing prerequisites are complete.

## E2E Behavior

- `SupabaseE2ETests` skips unless both `UNFADING_E2E_EMAIL` and `UNFADING_E2E_PASSWORD` are set.
- Live E2E coverage signs in, fetches the current user, creates a group, creates a memory, fetches group memories, and deletes the created memory.
- Group cleanup is not automated because no group deletion repository helper exists yet; use a dedicated E2E account/project.

## Archive Prep

- Archive script: `workspace/ios/scripts/archive.sh`.
- Export options: `workspace/ios/scripts/export-options.plist`.
- Signed IPA creation remains blocked until the user provides a valid Apple team ID.

## Screenshot Prep

- Existing UITests attach named screenshots.
- Harvest helper: `workspace/ios/scripts/harvest_screenshots.sh <Test.xcresult> [output_dir]`.
- Screenshots still need final manual curation for required App Store device sizes and marketing order.

## Local Verification

- `xcodegen generate` completed and regenerated `MemoryMap.xcodeproj`; the generated project includes `SupabaseE2ETests.swift` in `MemoryMapTests`.
- `bash -n scripts/archive.sh` passed.
- `bash -n scripts/harvest_screenshots.sh` passed.
- `plutil -lint scripts/export-options.plist` passed.
- Requested simulator test command could not complete in this sandbox:
  - First attempt failed because fresh `.deriveddata/r24` package resolution could not reach GitHub.
  - Retried with R23 cached SourcePackages and workspace-local package/cache paths.
  - Final `xcodebuild test` failure: Xcode reported no available device matching `platform=iOS Simulator,id=00FCC049-D60A-4426-8EE3-EA743B48CCF9`; CoreSimulatorService was repeatedly reported as connection invalid.
  - No final test count was produced by this environment.
