# R54 Share Extension Smoke Notes

## Build artifact

- Intended verification commands:
  - `xcodegen generate`
  - `xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r54-share build-for-testing`

## Real-device smoke flow

1. Install a signed build containing `UnfadingShareExtension`.
2. Open Photos on device and choose one image.
3. Tap Share and select `Unfading Share`.
4. Confirm Unfading launches via `unfading://composer`.
5. If the share payload carried a `PHAsset` local identifier, verify composer opens with the shared photo thumbnail and seeded time/place.
6. If the payload only carried a file representation, verify composer still opens; seeded photo handoff remains deferred until App Group container copy is implemented.

## Deferred

- App Group file handoff is prepared only by entitlement in this round.
- The main app does not yet import extension temp files from a shared container.
