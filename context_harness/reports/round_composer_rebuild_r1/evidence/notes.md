# R31 Composer Evidence Notes

## Needs-Confirm UX Flow
- Composer opens with `placeState == .needsConfirm`.
- Save button uses chip background/text tertiary and is disabled while `placeState != .confirmed`.
- `이 장소 맞아요` calls `confirmPlace()` and enables save.
- `장소 변경` reuses `PlacePickerSheet`; selected places call `applyPickedPlace(_:)` and become confirmed.
- `현재 위치로` calls `confirmCurrentLocation()` and confirms when a coordinate or closest match is available.

## Event RPC Call Path
- Event field opens `EventFieldSheet`.
- `EventFieldSheetModel.loadExistingEvent()` calls `findEventAt(groupId:timestamp:)`.
- Existing event defaults the binding to `.bindExisting(event)`.
- `.createNew(title:isTrip:endDate:)` is resolved during save by `MemoryComposerState.resolvedEventId(groupId:)`.
- Save calls `createEvent(groupId:title:startDate:endDate:reminderAt:)` before photo upload and passes the returned `event_id` into `DBMemoryInsert`.

## Participant Default Rule
- `applyParticipantDefaultsIfNeeded()` runs on Composer appear.
- `GroupMode.general` selects all loaded `groupStore.members.map(\.profiles.id)`.
- `GroupMode.couple` clears participant IDs and hides the participant section.
- Save writes `participant_user_ids` only for general groups; couple mode writes an empty array.

## Photo Seed Absorption
- Existing `applyFirstPhotoSeedIfAvailable()` path is retained.
- `applyPhotoSeed(_:)` still fills location/time from EXIF when appropriate.
- Any applied seed sets `showPhotoSeedNotice = true` and returns place to `needsConfirm`, preserving the required review step before save.

## Verification Attempts
- `xcodegen generate` completed and regenerated `MemoryMap.xcodeproj`.
- `xcodebuild test ... -derivedDataPath .deriveddata/r31 -resultBundlePath .deriveddata/r31/Test-R31.xcresult` was attempted 3 times.
- Test execution did not reach compilation because sandbox denied CoreSimulatorService and SwiftPM/clang cache writes under `/Users/jeonsihyeon`, and network access was unavailable for fresh package clone.
- `xcrun swiftc -parse` over modified Swift source/test files completed successfully as a syntax-only fallback.
