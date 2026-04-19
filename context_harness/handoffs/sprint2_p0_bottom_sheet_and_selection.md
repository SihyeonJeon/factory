# Sprint 2 — P0 Round: Main-screen bottom sheet + marker/cluster↔sheet sync

**Date:** 2026-04-12
**Baseline:** Sprint 1.5 green (build succeeded, 18/18 tests pass, evaluation_passed=true)
**Spec:** `context_harness/product_inputs/acceptance.md` lines 85–119 (main-screen interaction contract)
**Integration worktree:** `/Users/jeonsihyeon/factory/.worktrees/_integration`
**Lane:** ios_logic_builder (primary), ios UI
**Build command (from `workspace/ios/`):**
```
xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/memorymap_build test
```

---

## Why this round

Sprint 1.5 landed green but evaluator regex did not flag two real contract holes:

1. **P0-1 — Three-snap bottom sheet missing.** `MemoryMapHomeView` currently pins a static `MemorySummaryCard` through `.safeAreaInset(edge: .bottom)`. Acceptance §105–119 requires a *foreground animated bottom sheet* with three snap states (collapsed / default / expanded), Photos-event-grouped feel, and adaptive curation.
2. **P0-2 — Marker/cluster ↔ sheet sync missing.** Acceptance §91,93,95,118 require that tapping a marker or cluster replaces default curation with filtered content for that selection, and raises the sheet to its default snap.

Both must land in one bundled round so the sheet and selection binding are tested together.

---

## Files in scope (authoritative list — edit ONLY these + new files listed)

### Edit
- `workspace/ios/Features/Home/MemoryMapHomeView.swift` — remove `.safeAreaInset` summary card; host the new bottom sheet as a ZStack overlay; drive a `@StateObject MapSelectionStore` that publishes the current selection; bind marker/cluster taps to the store; raise sheet detent to `.default` on selection.
- `workspace/ios/Features/Home/MemorySummaryCard.swift` — convert into the collapsed-state content view (curated grouping header + tag strip). Keep its existing visual style but drop the hard-coded copy; it must render from a supplied `CuratedGrouping` model.
- `workspace/ios/Tests/MemoryMapTests.swift` — add tests listed in "Tests to add" below. Do not remove or weaken existing tests.

### Create
- `workspace/ios/Features/Home/MainBottomSheet.swift`
  - `enum MainSheetDetent { case collapsed, defaultBrowsing, expanded }` with `fraction` mapping: collapsed 0.18, default 0.48, expanded 0.92. A11y dynamic type forces `.expanded` only.
  - `struct MainBottomSheet<CollapsedContent, DefaultContent, ExpandedContent>: View` — pure view that takes three content builders and a `@Binding var detent: MainSheetDetent`. Internally uses a drag gesture + spring animation (`.interactiveSpring(response: 0.42, dampingFraction: 0.82)`) to snap between fractions. Must NOT use `sheet(...)` or `presentationDetents` — those conflict with the composer sheet and don't layer above the map the way the spec requires.
  - Must ignore bottom safe area, render a `.regularMaterial` capsule drag handle, and never cover the top header.
- `workspace/ios/Features/Home/MapSelectionStore.swift`
  - `@MainActor final class MapSelectionStore: ObservableObject`
  - `enum MapSelection: Equatable { case none; case marker(memoryID: UUID); case cluster(memoryIDs: [UUID], title: String) }`
  - `@Published var selection: MapSelection = .none`
  - `func select(marker memoryID: UUID)`, `func select(cluster memoryIDs: [UUID], title: String)`, `func clear()`
  - Pure state — no side effects. UI observes and reacts.
- `workspace/ios/Features/Home/CuratedGrouping.swift`
  - `struct CuratedGrouping: Identifiable, Equatable { let id: UUID; let title: String; let subtitle: String; let memoryIDs: [UUID] }`
  - `enum CuratedCurator { static func groupings(from memories: [DomainMemory]) -> [CuratedGrouping] }`
  - Implementation: group by `place.title` (case-insensitive), newest memory first inside each group. Title = place title, subtitle = `"\(count) memories · \(latest date relative)"`. Empty memories → return a single placeholder grouping with `memoryIDs: []` and subtitle `"Drop your first pin to start a grouping."` (adaptive, not hard-coded).
- `workspace/ios/Features/Home/MemoryDetailView.swift`
  - `struct MemoryDetailView: View` with `let memory: DomainMemory`. Shows title, place, timestamp, note, emotion tags, reaction count. Navigation target opened from the sheet's memory list. Next/prev buttons that walk the current filtered list via an injected `[DomainMemory]` and starting index. This satisfies §97 "dedicated memory detail page" and §98 "move to nearby or related memories".

### Do NOT touch
- `Shared/Domain/*` (data layer — stable)
- `SampleModels.swift` (tests depend on it)
- `Features/Groups/*`, `Features/Rewind/*`, `App/*`, `Info.plist`, `project.yml`
- Composer sheet — its `.presentationDetents` stay as-is; the new main bottom sheet is overlay-based, not a UIKit sheet, so there is no conflict.

---

## Contract: what the home screen must do after this round

1. `MemoryMapHomeView` renders four layers in a `ZStack`:
   - `Map` (full-screen, `.ignoresSafeArea()`)
   - floating top header (existing toolbar — keep as-is)
   - floating add-memory FAB (migrate the `+` toolbar button to a bottom-trailing `Circle`-shaped `Button` above the sheet at collapsed height; accessibility label unchanged)
   - `MainBottomSheet` as the foreground sheet
2. Sheet default detent on first appear: `.defaultBrowsing`.
3. Sheet content source of truth:
   - When `selection == .none`: collapsed shows the first `CuratedGrouping` as a compact summary header; default shows a vertical `List` of all `CuratedGrouping`s (Photos-style section rows); expanded shows all memories flat, newest-first, grouped under date headers ("Today", "Yesterday", "April 10", ...).
   - When `selection == .marker(id)`: collapsed shows a single-memory header; default shows the selected memory's card + up to 3 sibling memories sharing the same `place.title`; expanded navigates into `MemoryDetailView(memory:)` via `NavigationLink`. Sheet header must visibly differ from cluster/none — prefix `"Pin · "`.
   - When `selection == .cluster(ids, title)`: sheet header prefix `"Cluster · "`, content list = memories whose `id` is in `ids`, newest first. Different header color/icon from marker state so the two are distinguishable (§118).
4. Marker tap → `mapSelectionStore.select(marker:)` + raise `detent` to `.defaultBrowsing` if currently collapsed (§93).
5. Cluster tap → `mapSelectionStore.select(cluster:)` + raise `detent` to `.defaultBrowsing` (§91,93). *Clustering itself is out of scope for this round; simulate a cluster by treating any tap on the ambient map (background) as `clear()` and expose one test-only seam `func simulateClusterTap(memoryIDs:title:)` on the store — the real clustering engine lands in a later P1 round.*
6. Tapping the map background with no annotation hit → `clear()` + do NOT auto-lower the detent (user may have dragged it).
7. Curated list must be algorithmically derived from `memoryStore.memories`, never hard-coded copy (§117). Remove the "Sangsu rooftop dinner / 4 friends / Three years ago today..." hard-coded strings from `MemorySummaryCard`.
8. Memory row tap in any sheet state → `NavigationLink` push to `MemoryDetailView`. Detail view shows next/prev buttons that walk the currently visible filtered list.
9. Accessibility:
   - Drag handle has `.accessibilityLabel("Bottom sheet handle")` and `.accessibilityAdjustableAction` that cycles `collapsed → default → expanded → collapsed`.
   - In `dynamicTypeSize.isAccessibilitySize`, force detent to `.expanded` and hide the drag handle (single state).
   - All row taps keep ≥44pt hit targets.
10. No new SwiftLint-ish warnings; no force unwraps; `@MainActor` on stores.

---

## Tests to add (append to `MemoryMapTests.swift`)

Keep existing 18 tests green. Add at least:

1. `testCuratedGroupingsEmptyStatePlaceholder` — `CuratedCurator.groupings(from: [])` returns exactly one grouping with empty `memoryIDs` and the placeholder subtitle.
2. `testCuratedGroupingsMergeByPlaceTitle` — three memories at two places → two groupings, correct counts, newest first.
3. `testMapSelectionStoreMarkerSelection` — `store.select(marker: id)` sets `.marker`; `clear()` resets to `.none`.
4. `testMapSelectionStoreClusterSelection` — cluster selection preserves id order and title.
5. `testMainSheetDetentCyclesViaAccessibilityAction` — given a binding, invoking the adjustable-action closure cycles collapsed→default→expanded→collapsed.
6. `testMainSheetForcedExpandedUnderAccessibilitySize` — constructing the sheet with an accessibility size forces `.expanded` regardless of the binding's initial value.
7. `testMemoryDetailNextPrevBounds` — detail view's `moveToNext` / `moveToPrevious` clamp at list bounds without crashing.

All new tests must use `@MainActor` where stores are touched. Target ≥25 tests after this round.

---

## Acceptance checklist (red-team will verify)

- [ ] Build succeeds on iPhone 17 simulator.
- [ ] All tests pass, ≥25 total, 0 skipped.
- [ ] No hard-coded "Sangsu rooftop dinner" / "4 friends" / "Three years ago" strings remain anywhere under `Features/Home/`.
- [ ] `grep -rn "safeAreaInset" workspace/ios/Features/Home/` returns zero hits (the old static card mount is gone).
- [ ] `MainBottomSheet` file exists and is referenced from `MemoryMapHomeView`.
- [ ] Marker tap filters sheet content and sets detent to default (covered by a unit test using a view-model seam, not a UI test).
- [ ] Cluster header visibly differs from marker header (different SF Symbol + prefix).
- [ ] Dynamic-type-size A11y path forces `.expanded` and hides handle.
- [ ] `xcodegen generate` was run before the final `xcodebuild test`; fresh `MemoryMap.xcodeproj` includes every new Swift file.

---

## Non-goals (explicitly deferred)

- Real clustering algorithm (P1)
- Time filter animation (P1)
- Event containers / `EventStore` (P1)
- Camera capture (P1)
- Rewind reminder config UI (P1)
- First-photo metadata prefill (P1)

Do not attempt any of the above in this round. If scope seems to bleed, stop and write back to the handoff file describing the conflict.

---

## Known pitfalls from past rounds

- Codex MUST run `xcodegen generate` after adding Swift files, or the new files won't be in the xcodeproj target and tests will mysteriously compile without exercising them.
- Do not re-introduce `.sheet(...).presentationDetents` for the main bottom sheet — that clashes with the composer sheet because SwiftUI only hosts one sheet per presenter. The main sheet is overlay-based on purpose.
- Absolute paths only when dispatching from Python — relative `cwd=` breaks codex.
- Do not delete `SampleModels.swift` or `SampleMemoryPin.samples` — tests + empty-state context still depend on them.
- Korean reply convention applies to any status output.
