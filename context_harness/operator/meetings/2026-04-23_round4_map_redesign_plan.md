---
round: round_map_redesign_r1
stage: overall_planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round4-map-redesign
contract_hash: none
created_at: 2026-04-23T01:30:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---

# Meeting — R4 Plan: Map Redesign (shell + selection context)

## Context

R3 (43a7938) landed the 5-tab nav. MemoryMapHomeView still uses R2's MVP shape (static summary card via safeAreaInset). Deepsight shows: persistent 3-snap bottom sheet, filter chips row, top-left group chip, top-right search, FAB at bottom-right, cluster/pin selection changes sheet + filters content.

## Proposal

Merge slicing-manifest's "Map shell" + "Map selected context" into one R4 round. Rationale: they share the bottom sheet + filter chip + selection state scaffolding; splitting causes churn.

### New reusable modules

1. `workspace/ios/Shared/UnfadingBottomSheet.swift` — persistent 3-snap bottom sheet container. Public API: `UnfadingBottomSheet(snap: $snap) { content }`. Snap enum: `.collapsed` / `.default` / `.expanded` with fractions from `UnfadingTheme.Sheet`. Drag handle, gesture, spring animation.
2. `workspace/ios/Shared/UnfadingFilterChip.swift` — selectable filter chip. Coral selected state. Used in a horizontal scroll row.

### New state

3. `workspace/ios/Features/Home/MemorySelectionState.swift` — `@Observable`/`ObservableObject` store. Tracks selected pin, active filter, sheet snap.

### Refactors

4. `MemoryMapHomeView.swift` full rewrite using UnfadingBottomSheet + filter chips row + FAB via UnfadingPrimaryButtonStyle + group chip (stub leading to GroupHubView) + search stub.
5. `MemorySummaryCard.swift` accepts a selected-pin binding so it updates on pin selection.

### Tests

6. `UnfadingBottomSheetTests` — snap enum + fraction mapping.
7. `UnfadingFilterChipTests` — selected state rendering pattern.
8. `MemorySelectionStateTests` — selection toggle + filter toggle + sheet snap transition rules.

### Runtime capture
Simulator screenshots: default state, pin tap (selection), filter-chip selected.

## Non-goals

- Full group chip → group hub sheet (R9)
- Full search functionality (later round)
- Cluster rendering logic overhaul (kept as R2 shape; selection logic added)

## Challenge Section

### Risk
Custom bottom sheet overlay is complex — drag gesture, snap physics, keyboard interaction, safeArea handling. Mitigation: minimal drag math (height = `screenHeight * snap.fraction`, on-drag updates offset, on-end snaps to nearest). No keyboard interaction this round.

### Rejected alternative
Using `.sheet(isPresented:)` with `.presentationDetents([.fraction(0.22), ...])`. Rejected because sheet dismisses easily; we need a PERSISTENT bottom sheet that's always present as part of the map chrome.

### Objection
Adding 3 modules + 1 state + 1 big rewrite is a lot. But splitting causes redundant meetings/locks. Accept the larger scope; Codex review will catch issues.

## Decision

PROCEED. Scope locked to the 8 items above.
