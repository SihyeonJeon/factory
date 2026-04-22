# round_map_redesign_r1 spec

## Scope
Map shell + pin selection context per deepsight prototype. Persistent 3-snap bottom sheet, filter chips, FAB, pin selection updates selection state and sheet snap.

## Base commit
`43a7938`

## Deliverables

### New reusable modules
- `workspace/ios/Shared/UnfadingBottomSheet.swift` — persistent 3-snap sheet. Public API:
  ```swift
  struct UnfadingBottomSheet<Content: View>: View {
      init(snap: Binding<BottomSheetSnap>, @ViewBuilder content: () -> Content)
  }
  enum BottomSheetSnap: CaseIterable { case collapsed, default_, expanded
      var fraction: Double { /* UnfadingTheme.Sheet */ }
  }
  ```
- `workspace/ios/Shared/UnfadingFilterChip.swift` — selectable chip. Public API:
  ```swift
  struct UnfadingFilterChip: View {
      init(title: String, systemImage: String?, isSelected: Bool, action: @escaping () -> Void)
  }
  ```

### New state
- `workspace/ios/Features/Home/MemorySelectionState.swift` — `@MainActor ObservableObject`. Tracks: `selectedPinID`, `activeFilter`, `sheetSnap`. Methods: `select(_:)`, `clearSelection()`, `toggleFilter(_:)`.

### Refactors
- `workspace/ios/Features/Home/MemoryMapHomeView.swift` — uses UnfadingBottomSheet overlay, renders filter chips row below top chrome, FAB bottom-right using `.unfadingPrimary`, group chip top-left opening GroupHubView sheet, search icon top-right.
- `workspace/ios/Features/Home/MemorySummaryCard.swift` — accepts optional `SampleMemoryPin?` to show selected pin details; falls back to sample content when nil.

### Tests
- `workspace/ios/Tests/UnfadingBottomSheetTests.swift` — snap→fraction mapping, order, transitions.
- `workspace/ios/Tests/UnfadingFilterChipTests.swift` — view builder smoke + selected accent check.
- `workspace/ios/Tests/MemorySelectionStateTests.swift` — select/clearSelection/toggleFilter behavior.

### Localized strings added
- `UnfadingLocalized.Home` — `search`, `addMemoryFab`, `filterAll`, `filterDate`, `filterTrip`, `filterAnniversary`, `filterFood`.

## Non-goals
- Full group chip → sheet wiring (R9)
- Fully functional search
- Cluster/annotation visual overhaul

## Acceptance criteria (grep-checkable)
- All 3 new modules exist at specified paths.
- `UnfadingBottomSheet` used by `MemoryMapHomeView`.
- Filter chip row renders 5 chips (all/date/trip/anniversary/food).
- FAB uses `.unfadingPrimary`.
- `MemorySelectionState` used by MemoryMapHomeView.
- Zero inline colors in touched files (outside UnfadingTheme).
- Zero English literals in touched view files (Text/Label/accessibility).
- `xcodebuild test` exits 0, test count ≥ 34 + 10 new = 44.

## Source SHAs (inputs, read-only)
- `docs/design-docs/deepsight_tokens.md` sha256:638425b8c8aa5cbcf0826fc31980b31a8b5ebc0dd9ed6c669c03c6c7c9d9a59f
- Pre-round `MemoryMapHomeView.swift` sha256:(compute-at-impl)
