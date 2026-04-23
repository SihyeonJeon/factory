# round_group_hub_settings_r1 Eval Protocol

1. Run `xcodegen generate` from `workspace/ios`.
2. Run targeted unit test:
   `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MemoryMapTests/GroupHubTests -derivedDataPath .deriveddata/r35`
3. Run full requested suite:
   `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .deriveddata/r35`
4. If sandbox blocks package download or simulator access, record the exact blocker and any successful narrower verification.
