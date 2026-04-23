# R32 Memory Detail Sprint 28 — Evidence Notes

## Scope
- Implemented `MemoryDetailView` as a DBMemory-driven full-screen sheet surface.
- Added same-event carousel controls, KST meta strip, note, emotion chips, Sprint 28 section order, general-group participants, expense/weather detail, and inline "한 줄 더 쓰기".
- Added `SimilarPlaceCard`, `EventMemoryMiniGallery`, and `ParticipantAvatarRow`.

## Deferred
- `memory_extra_notes` or `memories.contribution_notes` persistence is deferred to R38.
- This round stores the extra line in client `@State` only and does not change DB schema, repositories, migrations, or Supabase RPCs.
- Weather API/data integration remains out of scope; the detail screen uses sample weather copy.

## Notes
- The active round lock file was not present at `context_harness/operator/locks/round_memory_detail_sprint28_r1.lock` in this fresh session.
- Evidence here is factual capture only, not a verifier verdict.

## Commands
- `xcodegen generate` completed and regenerated `workspace/ios/MemoryMap.xcodeproj`.
- `xcodebuild test -derivedDataPath .deriveddata/r32 -resultBundlePath .deriveddata/r32/Test-R32.xcresult -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16'` did not reach compile/test execution:
  - CoreSimulatorService was unavailable under sandbox.
  - New `r32` package checkout attempted network fetches and failed with `Could not resolve host: github.com`.
- Retry with `-clonedSourcePackagesDirPath .deriveddata/r31/SourcePackages -skipPackageUpdates` avoided network fetch but still did not reach compile/test execution:
  - CoreSimulatorService remained unavailable.
  - SwiftPM manifest loading attempted writes under `/Users/jeonsihyeon/.cache` and `/Users/jeonsihyeon/Library/Caches`, which sandbox denied.
- `git diff --check` passed.
