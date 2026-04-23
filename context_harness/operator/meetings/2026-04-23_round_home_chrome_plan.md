---
round: round_home_chrome_r1
stage: coding_1st
status: draft
participants: [codex]
decision_id: r29-home-chrome-plan
contract_hash: 1b689b3cddbdf0a0058449093d1220b68a9a08ee966a91498199a33f1b7ff340
---

## Context
- Round objective: align Map Home chrome coordinates, zIndex, fade behavior, and marker-selected visuals to the design handoff.
- Authoritative sections: Global Layout System, Map Home default, State Model / state transitions.
- Implementation scope: preserve MapKit map content and existing bottom sheet content; refine overlay layer placement.
- Test scope: add coordinate UITest and expanded-snap fade UITest; adjust selection-state unit expectations to default snap.

## Proposal
- Convert `MemoryMapHomeView` root to `ZStack(alignment: .topLeading)` and assign explicit zIndex values: Map 10, MapControls 26, FilterChipBar 28, TopChrome 30, BottomSheet 50.
- Compute `sheetTopY = screenH - 83 - safeBottom - ((screenH - 83 - safeBottom) * snap.fraction)` from `GeometryReader`; use that same formula for MapControls and shell-level FAB.
- Add `-UI_TEST_SHEET_SNAP=<collapsed|default|expanded>` parsing at app/shell entry so expanded-state chrome fade can be tested without simulator drag gestures.
- Apply selected-marker scale/halo and non-selected marker opacity through `MemorySelectionState.selectedPinID`.

## Questions
- None for this implementation pass. The README map color tokens are noted as SVG placeholder tokens and are not applied to MapKit.

## Counter / Review
- Risk: `FilterChipBar` visual spec says 32pt height, but existing chip touch targets are 44pt. I chose a 44pt accessibility frame for the native app while pinning top to 108pt; this preserves reliable tapping and is called out in evidence.
- Risk: XCUITest frame availability depends on accessibility tree identity for SwiftUI containers. Dedicated identifiers were added to the chrome containers and tests query descendants by identifier.
- Risk: `xcodebuild test` may require simulator and SwiftPM cache access outside workspace. The run command is still executed, and environment failures are recorded separately from code assertions.

## Convergence
- Proceeded with code changes because the contract explicitly assigns implementation to Codex and the requested files are inside the round scope.

## Decision
- Implemented the overlay coordinate model and test hooks in the iOS workspace.
- Added R29 artifact whitelist, this planning meeting, and evidence notes.

## Challenge Section
- The main challenge is the 32pt chip-bar height versus 44pt minimum native touch target. The implementation favors 44pt hit/element height while preserving the exact `top: 108` coordinate and chip visual style.
- The second challenge is that this session cannot be the final verifier under Author != Verifier. A fresh read-only verification session should review evidence and runtime frames when simulator access is available.
