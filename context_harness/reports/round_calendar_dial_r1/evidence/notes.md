# round_calendar_dial_r1 Evidence Notes

## Implementation Notes
- Month label now opens a month picker sheet with 7 years x 12 months and current month highlighting.
- Day Detail now includes selected date, sample sunny weather, event list card, and a general-group-only mint gradient plan card.
- RSVP is client-only via `RSVPStore`; DB persistence remains deferred.
- Notification action schedules a local notification when permitted and always shows the required bottom toast.
- UITest mode injects one deterministic future plan for the general group.

## Test Commands
- Passed: `xcodegen generate`
- Passed: `xcodebuild -list -project MemoryMap.xcodeproj`
- Blocked by sandbox before compile: `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r33`
- Blocked by sandbox before compile: `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r33 -skipPackageUpdates`
- Blocked by sandbox before compile: `xcodebuild build -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'generic/platform=iOS Simulator' -derivedDataPath .deriveddata/r33 -skipPackageUpdates`
- Test inventory after changes: 187 `func test...` methods under `workspace/ios/Tests` and `workspace/ios/UITests`.

## Sandbox Blockers
- Network is unavailable, so fresh `.deriveddata/r33` initially could not clone SwiftPM packages from GitHub.
- After copying local R32 package cache into `.deriveddata/r33`, Xcode/SwiftPM still attempted to write under `/Users/jeonsihyeon/.cache` and `/Users/jeonsihyeon/Library/Caches`, which is outside the writable sandbox.
- CoreSimulatorService access is also denied in this session.

## Deferred
- Real weather API.
- RSVP database persistence.
- Event place persistence beyond the current fallback label.
