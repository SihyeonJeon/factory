# R21 Profile Sync Evidence Notes

## Implementation Notes

- Added `DBProfilePreferences` and default decoding for omitted `preferences`.
- Added `ProfileRepository` and `SupabaseProfileRepository`.
- Reworked `UserPreferences` to mirror local defaults, bootstrap from cloud after auth, and debounce cloud writes with cancellable tasks.
- Updated `MemoryMapApp` to call `bootstrap(userId:)` on signed-in auth transitions.
- Updated Settings with a top profile section for display name editing and read-only email.
- Added Korean localized Settings keys.
- Added `ProfileSyncTests` covering DBProfile preference round-trip, bootstrap from mock repository, and debounced preference update.

## Verification Plan

- Run `xcodegen generate`.
- Run the requested `xcodebuild test` command against simulator `00FCC049-D60A-4426-8EE3-EA743B48CCF9`.
- If SPM dependency fetch blocks, stop and report the fetch blocker for operator rebuild.

## Verification Result

- `xcodegen generate` completed and regenerated `MemoryMap.xcodeproj`.
- `xcodebuild test` did not reach compilation or tests because SPM package resolution attempted GitHub fetches and failed with `Could not resolve host: github.com`.
- CoreSimulator also reported sandbox-local service/log access failures before package resolution, but the terminal blocker was dependency fetch.
