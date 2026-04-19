# Remediation Round 2 — Composer data-correctness + main-screen contract

**Date:** 2026-04-12
**Supersedes (as next round):** `sprint2_p0_bottom_sheet_and_selection.md` is DEFERRED — do not dispatch that until this round closes.
**Integration worktree:** `/Users/jeonsihyeon/factory/.worktrees/_integration`
**Lane:** ios_logic_builder (primary), ios UI merges into same worktree
**Build command (from `workspace/ios/`):**
```
xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/memorymap_build test
```

---

## Why this round exists

The 2026-04-12 re-evaluation exposed blockers the previous `evaluation_passed=true` regex missed. Three evaluators independently confirmed:

**Red-team (opus-4-6, 12:40):** BLOCKED — "Sprint 1.5 landed a cosmetic fix … left the core data-correctness defect untouched."
**HIG Guardian (sonnet-4-6):** BLOCKED — 2 new release blockers.
**Visual QA (sonnet-4-6):** BLOCKED — 2 hard blockers visually confirmed.

The build is still green and 18/18 tests still pass. That is *non-evidence*: none of the 18 tests cover the composer save path.

---

## P0 Blockers (MUST all land in this round)

### P0-1 — Hallucinated coordinates on every user memory *(Red-team P0 #1)*

**File:** `workspace/ios/Features/Home/MemoryComposerSheet.swift`
**Current state:**
- `:19` — `@State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 37.5519, longitude: 126.9215)` (Sangsu-dong rooftop default)
- `:217–218` — the only read sites; `selectedCoordinate` is **never mutated** anywhere in the file.
- `ManualPlacePickerSheet.select(_:)` at `:377–380` writes `selectedPlace` (title only), coordinate untouched.
- `handleCurrentLocationTap()` at `:238–245` just sets `selectedPlace = "Current location"` literal; never consults `LocationPermissionStore` or `CLLocationManager.location`.

**Consequence:** every memory the user saves pins to the same Sangsu-dong rooftop coordinate regardless of what place they picked or whether location was authorized. This destroys the Memory Map's core proposition.

**Fix (concrete):**

1. Extend `PlaceSuggestion` in `workspace/ios/Shared/SampleModels.swift` with `latitude: Double` and `longitude: Double` stored properties. Give each of the three existing samples a real coordinate:
   - `sangsu-rooftop` → `(37.5519, 126.9215)`
   - `jeju-sunrise` → `(33.4592, 126.9407)`
   - `yeouido-park` → `(37.5285, 126.9327)`
   Keep the existing `static func matching(_:)` behavior intact — existing tests (`testPlaceSuggestionMatchingUsesTitleAndSubtitle`, etc.) must continue to pass. You MAY add fields to the struct because the existing tests only compare titles; do NOT remove or rename any existing field.

2. Change `ManualPlacePickerSheet` to bind a `PlaceSuggestion?` (or a new `SelectedPlace` struct containing title + coordinate), not a bare `String`. Signature change:
   ```swift
   struct SelectedPlace: Equatable { let title: String; let coordinate: CLLocationCoordinate2D }
   ```
   `ManualPlacePickerSheet` takes `@Binding var selection: SelectedPlace?` and on row tap writes `.init(title: suggestion.title, coordinate: CLLocationCoordinate2D(latitude: suggestion.latitude, longitude: suggestion.longitude))` before dismissing. The "Use typed place" freeform row must refuse to commit unless the user has already chosen a base suggestion OR falls back to the current map center — pick the simpler of the two and document it in the file.

3. In `MemoryComposerSheet`, replace `@State private var selectedPlace = "Sangsu-dong rooftop"` and `@State private var selectedCoordinate = …` with a single `@State private var selectedPlace: SelectedPlace? = nil`. The `LabeledContent("Selected place")` renders `selectedPlace?.title ?? "Tap to choose"`. `saveMemory()` refuses to proceed when `selectedPlace == nil` — return `false` and surface an inline error.

4. Wire `handleCurrentLocationTap()` to actually read a coordinate:
   - Extend `LocationPermissionStore` with a `currentCoordinate: CLLocationCoordinate2D?` computed from `retainedLocationManager?.location?.coordinate` (nil when unavailable or unauthorized). This is a read-only accessor — it must NOT call `startUpdatingLocation`, to keep tests deterministic.
   - In the composer, when permission is `.authorized` and `currentCoordinate` is non-nil, set `selectedPlace = SelectedPlace(title: "Current location", coordinate: coord)`. When authorized but `currentCoordinate == nil`, show a one-line inline warning "Couldn't fetch a live fix — choose a place manually" and do NOT mutate `selectedPlace` (no silent hallucination).

5. Save toolbar `.disabled(...)` must additionally disable when `selectedPlace == nil`.

6. Update the existing `LocationPermissionRecoverySheet` `@Binding var selectedPlace: String` to match the new type — pass `SelectedPlace?` through, or refactor so the recovery sheet does not touch the place at all (cleaner). The recovery sheet's only job is to route to the manual picker.

**Test to add:** `testComposerSaveRefusesWithoutPlace` and `testComposerSavePersistsChosenCoordinate` — the latter constructs a `MemoryStore`/`GroupStore`, drives the composer's `saveMemory()` with a non-default `SelectedPlace`, and asserts `memoryStore.memories.first?.place.latitude != 37.5519` (i.e. the default is not used). These tests will require breaking out `saveMemory()` into a testable view-model seam OR making it `internal` and calling it directly from a `@MainActor` XCTestCase.

---

### P0-2 — Dead merge-suggestion banner + silent auto-reaction *(Red-team P0 #2)*

**File:** `workspace/ios/Features/Home/MemoryComposerSheet.swift` `:132–141, 221–224`

`saveMemory()` sets `mergeSuggestionTitle`, returns `true`, and the caller dismisses the sheet at `:126` — so the `.overlay` banner at `:132–141` is never seen. Meanwhile `memoryStore.react(to: existing.id)` fires regardless, auto-reacting to a memory the user was never told about.

**Pick one of two fixes:**

**Option A (prefer):** remove the auto-react entirely. Merge suggestion becomes a map-level affordance in a later round. Delete the `mergeSuggestionTitle` state, the overlay at `:132–141`, the `memoryStore.react(to: existing.id)` call, and leave a TODO comment referencing this round.

**Option B:** on merge detection, `saveMemory()` returns `false`, and the sheet transitions to a confirmation state (new `@State var mergeCandidate: DomainMemory?`) with two buttons: "Merge into history" (proceeds to `add()` + `react()` + dismiss) and "Save as new memory" (proceeds to `add()` without react + dismiss). No silent react.

Option A is smaller and clearly correct; Option B preserves the design intent. Choose A unless you can land B cleanly within this round.

**Test to add:** `testComposerDoesNotAutoReactOnSave` — after a save, `memoryStore.memories.first?.reactionCount == 0`.

---

### P0-3 — "Create a Group" CTA dead-ends *(Red-team P0 #3)*

**File:** `workspace/ios/Features/Home/MemoryComposerSheet.swift` `:46–48`

Current code just `dismiss()`es without routing the user to the Groups tab.

**Fix:**
- Add a selection binding to `RootTabView` — introduce `@State private var selectedTab: AppTab` and a shared enum. Wire it down via a `@Binding` to any view that needs to request a tab change. The simplest cross-cutting path is a lightweight `TabRouter` `ObservableObject` in environment:
  ```swift
  @MainActor final class TabRouter: ObservableObject {
      @Published var selected: AppTab = .map
  }
  enum AppTab: Hashable { case map, rewind, groups }
  ```
  `MemoryMapApp.swift` injects `TabRouter()`. `RootTabView` binds its `TabView` selection to `tabRouter.selected`. `MemoryComposerSheet`'s "Create a Group" button calls `tabRouter.selected = .groups` then `dismiss()`.
- Create `workspace/ios/Shared/TabRouter.swift` for the new store. Do NOT scatter routing logic.

**Test to add:** `testCreateGroupCTARoutesToGroupsTab` — inject a fake `TabRouter`, tap the CTA in a headless test (construct the button's action closure), assert `router.selected == .groups`.

---

### P0-4 — Main bottom sheet is not a real sheet *(HIG B1, Visual QA B1)*

**Files:** `workspace/ios/Features/Home/MemoryMapHomeView.swift` `:42–47`, `workspace/ios/Features/Home/MemorySummaryCard.swift`

Current `.safeAreaInset(edge: .bottom) { MemorySummaryCard() }` renders a fixed translucent card with no drag handle and no snap states. Acceptance §105–119 requires a three-snap foreground sheet.

**Fix:** Port the plan from the deferred `sprint2_p0_bottom_sheet_and_selection.md` — but **minimum viable** for this round:

1. Delete the `.safeAreaInset` mount.
2. Add `@State private var showingHomeSheet = true` and a `.sheet(isPresented: $showingHomeSheet)` that renders a new `HomeSummarySheet` view.
3. `HomeSummarySheet` uses `.presentationDetents([.height(140), .medium, .large])` with `.presentationDragIndicator(.visible)` and `.interactiveDismissDisabled(true)` and `.presentationBackgroundInteraction(.enabled(upThrough: .large))`.
4. In `dynamicTypeSize.isAccessibilitySize`, force `[.large]` only.
5. The composer uses its own `.sheet(isPresented: $showingComposer)` — SwiftUI cannot present two sheets from the same presenter simultaneously, so when `showingComposer` flips to true you must temporarily lower the home sheet: either (a) set `showingHomeSheet = false` on composer open and restore on close, or (b) present the composer from the home sheet instead of from `MemoryMapHomeView`. Pick (a) for smaller blast radius.

This satisfies HIG B1 without taking on the full marker/cluster sync scope. That larger scope stays in `sprint2_p0_bottom_sheet_and_selection.md` for the next round.

**Test to add:** none required for this blocker — it's a view-tree change. Verify visually in the evaluator screenshot.

---

### P0-5 — MemorySummaryCard is fully placeholder copy *(HIG B2, Visual QA B2)*

**File:** `workspace/ios/Features/Home/MemorySummaryCard.swift`

Every visible string is hardcoded ("Tonight's rewind", "Sangsu rooftop dinner", "Three years ago today…", "4 friends", "Joy / Night out / Photo set"). Acceptance blocks "placeholder-heavy layout."

**Fix:**
1. Rename to `HomeSummarySheet` and move into `Features/Home/HomeSummarySheet.swift`. Delete the old `MemorySummaryCard.swift`.
2. `@EnvironmentObject var memoryStore: MemoryStore`. If `memoryStore.memories.isEmpty`, render `ContentUnavailableView("No memories yet", systemImage: "mappin.slash", description: Text("Tap the + button above to drop your first pin."))`.
3. Otherwise render a vertical `List` of up to 10 rows, newest-first. Each row shows `memory.place.title`, the first 80 chars of `memory.note`, the emotion chips (from live `memory.emotions`), and a relative timestamp via `Date.FormatStyle.relative(presentation: .named)`.
4. No hardcoded strings referring to "Sangsu rooftop dinner", "3 years ago", "4 friends", or the three legacy tag labels anywhere in the file.
5. After this change, `grep -rn "Sangsu rooftop dinner\|Tonight's rewind\|Three years ago" workspace/ios/Features/Home/` must return zero hits.

**Test to add:** `testHomeSummarySheetEmptyStateRendersContentUnavailable` — construct the view with an empty `MemoryStore`, walk the view hierarchy, assert the `ContentUnavailableView` path is reached (use `ViewInspector`-style approach only if already available; otherwise add a pure-model seam `func hasMemories() -> Bool` and test that).

---

## P1 Items (land if scope permits, else defer to next round)

- **PhotosPicker identifier correctness** — `MemoryComposerSheet.swift:231` uses `PhotosPickerItem.itemIdentifier` as `photoLocalIdentifiers`. `itemIdentifier` is an opaque picker item ID, not a stable `PHAsset.localIdentifier`. If the intended later consumer is a Photos library lookup, this is wrong. Either rename the field to `photoItemIDs` to reflect reality, or resolve each picker item to a `PHAsset` via `loadTransferable` and store the real local identifier. Pick the rename for this round (less risk).
- **Dynamic current-location fix** beyond what P0-1 requires — if `CLLocationManager.location` is nil, do not attempt to start updating in this round.

Do NOT start: persistence (G1), multi-group picker (G2), clustering, time filter, rewind reminder config, camera capture, first-photo metadata prefill. Those are later rounds.

---

## Files in scope (authoritative)

### Edit
- `workspace/ios/Features/Home/MemoryComposerSheet.swift`
- `workspace/ios/Features/Home/MemoryMapHomeView.swift`
- `workspace/ios/Shared/LocationPermissionStore.swift`
- `workspace/ios/Shared/SampleModels.swift` *(extend `PlaceSuggestion` with lat/lng only — do NOT touch `SampleMemoryPin`, `GroupPreview`, `MemoryComposerEvidenceMode`, or `MemoryDraftTag`)*
- `workspace/ios/App/RootTabView.swift`
- `workspace/ios/App/MemoryMapApp.swift`
- `workspace/ios/Tests/MemoryMapTests.swift`
- `workspace/ios/project.yml` *(only if new Swift files need to be added; `xcodegen` regenerates the project)*

### Create
- `workspace/ios/Shared/TabRouter.swift`
- `workspace/ios/Shared/SelectedPlace.swift` *(the new `SelectedPlace` struct — keep it small)*
- `workspace/ios/Features/Home/HomeSummarySheet.swift`

### Delete
- `workspace/ios/Features/Home/MemorySummaryCard.swift` (fully replaced by `HomeSummarySheet.swift`)

### Do NOT touch
- `Shared/Domain/*` (data layer stable — `DomainMemory`, `DomainGroup`, `MemoryStore`, `GroupStore` keep their existing shapes)
- `Features/Groups/*`, `Features/Rewind/*`
- `App/Info.plist`
- Any existing test name or assertion — append new tests, do not rewrite existing ones

---

## Acceptance checklist (red-team will verify)

- [ ] `grep -rn "latitude: 37.5519" workspace/ios/Features/` returns **zero** hits (no composer hardcoded default remaining).
- [ ] `grep -rn "Sangsu rooftop dinner\|Tonight's rewind\|Three years ago\|4 friends" workspace/ios/Features/Home/` returns **zero** hits.
- [ ] `grep -rn "safeAreaInset" workspace/ios/Features/Home/` returns **zero** hits.
- [ ] `grep -n "selectedCoordinate" workspace/ios/Features/Home/MemoryComposerSheet.swift` returns **zero** hits (field deleted, replaced by `SelectedPlace`).
- [ ] `MemoryMapHomeView` presents `HomeSummarySheet` via `.sheet(isPresented:)` with `presentationDetents`.
- [ ] `HomeSummarySheet` renders from live `MemoryStore` and shows `ContentUnavailableView` when empty.
- [ ] `TabRouter` exists and `RootTabView`'s `TabView` binds its selection to it.
- [ ] Composer "Create a Group" CTA sets `tabRouter.selected = .groups` before dismissing.
- [ ] Composer `saveMemory()` returns `false` and shows inline error when `selectedPlace == nil`.
- [ ] Composer authorized-location path fetches a real coordinate OR shows the warning — never silently falls back to Sangsu-dong.
- [ ] No silent `memoryStore.react(to:)` call on save (Option A path).
- [ ] New tests: `testComposerSaveRefusesWithoutPlace`, `testComposerSavePersistsChosenCoordinate`, `testComposerDoesNotAutoReactOnSave`, `testCreateGroupCTARoutesToGroupsTab`, `testHomeSummarySheetEmptyState` — all pass.
- [ ] Total test count ≥ 23 (was 18). Zero skipped, zero failures.
- [ ] `xcodegen generate` was run before the final `xcodebuild test`.
- [ ] Build succeeds on iPhone 17 simulator.
- [ ] Fresh evaluator screenshot (`xcode_runtime_screenshot.png`) shows a visible drag handle on the home sheet.

---

## Known pitfalls (do not re-learn)

- **Worktree workspace is gitignored** — changes never appear in `git log`. Verify landings by re-reading files under `.worktrees/_integration/workspace/ios/`.
- **`xcodegen generate` is mandatory after adding Swift files.** Codex has forgotten this three times. If you add a new file and skip xcodegen, the file compiles locally but is not part of the test target, and your tests will "pass" without actually running.
- **Absolute `cwd=` only** when dispatching — relative paths break codex with ENOENT.
- **Presenting two `.sheet`s from one presenter does not work** — that's why `showingHomeSheet` must flip off during composer presentation.
- **SampleModels.swift tests only assert titles** — adding fields with default values is safe; removing or renaming fields will break `testPlaceSuggestionMatchingUsesTitleAndSubtitle`.
- **Korean replies only, terse, no emoji** when status-reporting back.

---

## Expected dispatch

```python
from pathlib import Path
from master_router import fix_bug

repo = Path('/Users/jeonsihyeon/factory/.worktrees/_integration').resolve()
brief = Path('/Users/jeonsihyeon/factory/context_harness/handoffs/remediation_round_2.md').resolve()

result = fix_bug(
    f'Read the remediation packet at {brief} and apply all P0 fixes exactly as specified. '
    f'Edit only the files listed under "Files in scope". '
    f'After edits, run xcodegen + xcodebuild test from workspace/ios and report the test count + result.',
    cwd=repo,
    allow_fallback_roles=False,
    preferred_role='ios_logic_builder',
)
```

Do not dispatch until user confirms the plan. The evaluation log file at `/tmp/reeval_20260412.log` and the three reports under `context_harness/reports/` are the source of truth for the blocker list above.
