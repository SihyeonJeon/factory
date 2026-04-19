# Sprint 3 — Camera Capture, Cluster Interaction, Photo Metadata Prefill

**Date:** 2026-04-13
**Prerequisite:** Sprint 2 P1 + Remediation r4 green (42/42 tests)
**Goal:** 6 features + evaluator polish. All tests green after.

---

## Feature 1: In-app Camera Capture (Epic 2)

### Acceptance criteria
- Photo input sources must include photo library, document picker, and in-app capture.
- In-app capture should attach capture time metadata and attach location metadata whenever location permission is granted.

### Implementation spec

1. **`MemoryComposerSheet.swift` modification**
   - Add a camera button alongside the existing PhotosPicker
   - Use SwiftUI's `@Environment(\.isPresented)` + UIImagePickerController wrapper or iOS 17+ camera APIs
   - Create `CameraCaptureView` as a `UIViewControllerRepresentable` wrapping `UIImagePickerController` with `.sourceType = .camera`
   - On capture: extract EXIF metadata (date, GPS coordinates) from the captured image
   - Attach captured image to the memory's photo array
   - If location permission granted and GPS present in capture: auto-populate `selectedPlace` with reverse-geocoded address

2. **`Features/Home/CameraCaptureView.swift`** (NEW)
   - `UIViewControllerRepresentable` for `UIImagePickerController`
   - Delegate handles `didFinishPickingMediaWithInfo`
   - Extract `[.originalImage]`, creation date from `PHAsset` or EXIF dict
   - Extract GPS from `kCGImagePropertyGPSDictionary`
   - Return via binding: `UIImage` + optional `CLLocationCoordinate2D` + optional `Date`

3. **`MemoryComposerSheet.swift` modification**
   - Add "Document Picker" option using `.fileImporter(isPresented:allowedContentTypes:[.image])` 
   - Parse imported image for EXIF metadata same as camera path

### Tests to add
- `testCameraCaptureViewExists` (type check)
- `testComposerAcceptsDocumentPickerImage`

---

## Feature 2: First-photo Metadata → Place Prefill (Epic 2)

### Acceptance criteria
- The first uploaded photo's metadata should prefill place and time when available.
- The place field should default to a readable address or place label, not raw coordinates.
- The representative coordinate should remain stable unless the user explicitly changes the place.

### Implementation spec

1. **`MemoryComposerSheet.swift` modification**
   - When the first photo is selected (from library, camera, or document picker):
     - Extract EXIF GPS coordinates
     - Reverse geocode via `CLGeocoder().reverseGeocodeLocation()` → readable place name
     - Auto-fill `selectedPlace` with the geocoded result
     - Auto-fill time from EXIF `DateTimeOriginal`
   - Show a confirmation banner: "Place set from photo: [place name]" with a "Change" button
   - User can override via existing ManualPlacePickerSheet or current location

2. **`Shared/PhotoMetadataExtractor.swift`** (NEW)
   - `static func extractMetadata(from data: Data) -> PhotoMetadata?`
   - `struct PhotoMetadata { date: Date?, coordinate: CLLocationCoordinate2D? }`
   - Uses `CGImageSource` + `kCGImagePropertyExifDictionary` + `kCGImagePropertyGPSDictionary`

### Tests to add
- `testPhotoMetadataExtractorParsesGPS`
- `testComposerPrefillsPlaceFromPhoto`

---

## Feature 3: Cluster Tap → Zoom + Filter (Epic 3)

### Acceptance criteria
- Cluster taps zoom into the selected area.
- Cluster taps must also filter bottom-sheet content to the memories represented by that cluster.
- Marker selection should automatically raise the bottom sheet to its default browsing height.

### Implementation spec

1. **`MemoryMapHomeView.swift` modification**
   - On cluster annotation tap:
     - Animate map region to fit all pins in the cluster with padding
     - Set `mapSelectionStore.selection = .cluster(memoryIDs: [...], title: clusterTitle)`
   - On single marker tap:
     - Set `mapSelectionStore.selection = .marker(memoryID: id)`
     - Raise `MainBottomSheet` to default snap (0.48) via binding

2. **`MainBottomSheet.swift` modification**
   - When `mapSelectionStore.selection` changes from `.none`:
     - Animate sheet to default snap height
     - Filter displayed memories to match selection
   - Show clear selection button in sheet header when filtered
   - `.none` state returns to curated default view

3. **`MapSelectionStore.swift` modification** (if needed)
   - Ensure `select()` triggers `objectWillChange` for SwiftUI binding

### Tests to add
- `testClusterSelectionFiltersMemories`
- `testMarkerSelectionRaisesSheet`
- `testClearSelectionRestoresDefault`

---

## Feature 4: Reactions UI (Epic 2)

### Acceptance criteria
- Allow reactions to other members' memory records.

### Implementation spec

1. **`Features/Home/MemoryDetailView.swift` modification**
   - Add reaction bar below memory content
   - Show `EmotionTag.allCases` as tappable reaction chips
   - Tap calls `memoryStore.react(to: memory.id, emotion: tag)`
   - Show reaction count per emotion below the memory
   - Highlight user's own reaction

### Tests to add
- `testReactToMemory`
- `testReactionCountUpdates`

---

## Feature 5: Merge Suggestion Action (Epic 2)

### Acceptance criteria
- Suggest merging when the same place is revisited.

### Implementation spec

1. **`MemoryComposerSheet.swift` modification**
   - After place is confirmed, check `memoryStore.memories.filter { $0.place.title == selectedPlace.title }`
   - If matches found: show merge suggestion banner "You've been here before! Merge with previous visit?"
   - "Merge" → call `memoryStore.suggestMerge(memoryID:)` + attach to existing memory's place
   - "Keep separate" → dismiss banner, proceed normally

### Tests to add
- `testMergeSuggestionAppearsOnRevisit`

---

## Feature 6: Group Management (Epic 1)

### Acceptance criteria
- Group owners can remove members and delete the group.

### Implementation spec

1. **`Features/Groups/GroupHubView.swift` modification**
   - Add swipe-to-delete on group rows (owner only)
   - Add member list view with remove button per member (owner only)

2. **`Shared/Domain/GroupStore.swift` modification**
   - `func removeMember(_ memberID: UUID, from groupID: UUID)`
   - `func deleteGroup(_ groupID: UUID)` — only if caller is owner

### Tests to add
- `testOwnerCanRemoveMember`
- `testOwnerCanDeleteGroup`
- `testNonOwnerCannotDelete`

---

## Evaluator Polish (from Remediation r4 feedback)

1. **Emotion chip VoiceOver** — add `.accessibilityLabel` + `.accessibilityHint` on `EmotionChip` in `HomeSummarySheet.swift` (~line 76) and inline emotion `Label` in `MemoryMapHomeView.swift` (~line 500)
2. **Cold-launch regression test** — add `testRewindReminderStoreInitDoesNotCallRequestAuthorization` spy-based test
3. **Slider hint** — add `.accessibilityHint("Adjust reminder radius")` on radius Slider in `RewindSettingsView.swift`

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 42 existing tests must pass. New tests bring total to ~55+.
- Use `NSCameraUsageDescription` already present in Info.plist.
- Camera features must gracefully handle simulator (no physical camera) — check `UIImagePickerController.isSourceTypeAvailable(.camera)`.
- Search for leftover placeholders after: `rg -n 'TODO\|FIXME\|HACK\|placeholder' workspace/ios/Features/ workspace/ios/Shared/`
