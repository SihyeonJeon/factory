# round_phase3_final_r1 Eval Protocol

## Commands

1. `xcodegen generate`
2. `bash -n workspace/ios/scripts/archive.sh`
3. `plutil -lint workspace/ios/scripts/export-options.plist`
4. `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r50 -resultBundlePath .deriveddata/r50/Test-R50.xcresult`

## Evidence Rules

- Capture factual command results only.
- If the regression fails before test execution, report the real exit code, `.xcresult` status, and executed test count.
- Distinguish the latest historical green baseline from the current sandbox rerun.
- Do not claim TestFlight readiness beyond the four explicitly deferred operator actions.
