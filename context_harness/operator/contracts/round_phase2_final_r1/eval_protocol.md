# round_phase2_final_r1 Eval Protocol

## Commands

1. `xcodegen generate`
2. `bash -n workspace/ios/scripts/archive.sh`
3. `plutil -lint workspace/ios/scripts/export-options.plist`
4. `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r40 -resultBundlePath .deriveddata/r40/Test-R40.xcresult`
5. `scripts/harvest_screenshots.sh .deriveddata/r40/Test-R40.xcresult <evidence_output_dir>` when possible

## Evidence Rules

- Capture factual command results only.
- If the test bundle fails before execution, report `failedToStart` and executed test count `0`.
- Do not claim screenshot harvest success unless PNG files are exported into evidence.
- Keep deferred items limited to Phase 3 external or backend actions.
