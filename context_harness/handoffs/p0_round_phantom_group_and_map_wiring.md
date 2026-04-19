# P0 Remediation Packet — Sprint 1.5

Round goal: close the two P0 gaps that make Sprint 1's data layer cosmetic.

## Current state (2026-04-12)

- Build: BUILD SUCCEEDED, 16/16 tests pass on integration worktree.
- Data layer landed: `Shared/Domain/MemoryDomain.swift`, `MemoryStore.swift`, `GroupStore.swift`.
- `MemoryComposerSheet.saveMemory()` writes to `MemoryStore`, but with two defects:
  1. If `groupStore.groups` is empty, the saved memory falls into a fresh phantom `UUID()` and becomes unreachable.
  2. The saved memory never appears on the map — `MemoryMapHomeView` still iterates `SampleMemoryPin.samples` only.
- Combined effect: a user who taps Save sees no feedback and no map pin. The "epic 1 ↔ epic 3" connection does not exist.

## Files in scope

Edit only:
- `workspace/ios/Features/Home/MemoryMapHomeView.swift`
- `workspace/ios/Features/Home/MemoryComposerSheet.swift`
- `workspace/ios/Features/Home/MemoryPinMarker.swift` (only if a new initializer is needed)
- `workspace/ios/Tests/MemoryMapTests.swift` (add coverage)

Do NOT touch:
- `Shared/Domain/*` — domain model is stable; no signature changes
- `Shared/SampleModels.swift` — do not delete or rename. `SampleMemoryPin` may still be rendered alongside store-backed pins as background context, but store-backed pins must take visual priority.
- `Shared/LocationPermissionStore.swift`
- `App/MemoryMapApp.swift`, `App/RootTabView.swift`, `App/Info.plist`, `project.yml`
- Any file outside `workspace/ios/`

## P0-1 — Phantom group guard

### Problem
`MemoryComposerSheet.saveMemory()` line containing
`let groupID = groupStore.groups.first?.id ?? UUID()`
silently writes memories into a UUID that no group, store, or query will ever see.

### Required fix
1. Remove the `?? UUID()` fallback.
2. Add `@EnvironmentObject` access to `groupStore` (already present) and gate the Save toolbar button:
   - `Save` is `.disabled` when `note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || groupStore.groups.isEmpty`.
3. When `groupStore.groups.isEmpty`, render a non-blocking inline notice at the top of the Form (above the existing sections), with copy:
   > "Create a group first. Memories belong to a shared group so the rest of your members can see them."
   and a `Button("Create a Group")` that dismisses the composer sheet (the user can then tap the Groups tab).
4. `saveMemory()` must early-return when `groupStore.groups.first` is nil — no UUID fallback, no MemoryStore write.

### Acceptance
- Composer with no groups: Save button is disabled and grey, banner visible, no MemoryStore mutation possible.
- Composer with at least one group: Save button enables once note is non-empty, writes a memory whose `groupID` matches `groupStore.groups.first!.id`.

## P0-2 — Map ↔ MemoryStore wiring

### Problem
`MemoryMapHomeView` body contains
```
Map(position: $cameraPosition) {
    ForEach(SampleMemoryPin.samples) { pin in
        Annotation(pin.title, coordinate: pin.coordinate) {
            MemoryPinMarker(pin: pin)
        }
    }
}
```
Memories saved by the composer never render.

### Required fix
1. Add `@EnvironmentObject private var memoryStore: MemoryStore` to `MemoryMapHomeView`.
2. Inside the `Map { ... }` builder, render store-backed pins:
   ```
   ForEach(memoryStore.memories) { memory in
       Annotation(memory.place.title, coordinate: memory.place.coordinate) {
           MemoryPinMarker.storeBacked(title: memory.place.title)
       }
   }
   ```
   Keep the existing `SampleMemoryPin.samples` loop as a secondary layer (so the empty-state map still has visual context). Store-backed annotations must visually dominate (e.g. `.tint(.accentColor)` or a filled marker).
3. Add a small initializer or static helper on `MemoryPinMarker` so it can be constructed from a title string only — do NOT change the existing `init(pin:)` signature; add a new convenience that returns the same view for store-backed memories. If trivial, just reuse the existing marker by mapping `DomainMemory` → an in-place `SampleMemoryPin`-shaped struct, but prefer the new initializer to avoid leaking domain types into `SampleModels.swift`.
4. After save, the camera position should not auto-recenter — leave `cameraPosition` untouched.

### Acceptance
- Saving a memory at `(37.5519, 126.9215)` from the composer (with one existing group) immediately makes a new annotation visible on the map after the sheet dismisses.
- Existing `SampleMemoryPin` annotations remain visible (regression check for empty-state context).

## Test additions (`workspace/ios/Tests/MemoryMapTests.swift`)

Add two `@MainActor` tests; do not delete or modify existing tests.

1. `testMemoryStoreOnlySurfacesPersistedMemoriesPerGroup` — create two groups, add one memory to each, assert `memoryStore.memories(for: groupAID)` returns exactly the group A memory.
2. `testGroupStoreCreateGroupAddsCurrentUserAsMember` — already covered indirectly; add an explicit assertion that `group.memberIDs == [store.currentUserID]`.

## Build verification

After edits:
1. `cd workspace/ios && xcodegen generate`
2. `xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test`
3. Expected: BUILD SUCCEEDED, 18/18 tests pass.

## Required behavior

- Smallest change set that satisfies both acceptance sections.
- No domain model changes, no new files outside `Tests/`.
- No comments unless the WHY is non-obvious.
- Preserve every existing public API on `MemoryStore`, `GroupStore`, and `MemoryPinMarker`.
- Do not add backwards-compatibility shims.

## Out of scope (next round)

- In-app camera capture
- Three-snap main-screen bottom sheet (acceptance.md 105–119)
- Time filtering, marker-cluster sync
- Event containers, rewind reminder configuration
- Photo metadata prefill
