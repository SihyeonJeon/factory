---
round: round_sheet_fidelity_r1
stage: coding_1st
status: draft
decision_id: 20260423-sheet-fidelity
codex_session_id: fresh
participants: [claude_code, codex]
contract_hash: none
---

## Context

- Authoritative design source: `docs/design-docs/Unfading Prototype.html` lines 780-1100.
- Stream A owns sheet/layout fidelity only: F1, F2, F13, F14.
- Stream B owns composer/location-store work; Stream C2 owns calendar work.
- `project.yml`, `UnfadingLocalized.swift`, `MemoryComposerSheet.swift`, `MemoryComposerState.swift`, `LocationPermissionStore.swift`, `CalendarView.swift`, and `MemoryCalendarStore.swift` are out of scope for edits.

## Proposal

- Move sheet snap fractions to `0.085 / 0.52 / 1.0` in the sheet snap model.
- Render expanded sheet with no top radius, no shadow, and no handle.
- Use live drag height from translation and resolve release by nearest velocity-projected snap.
- Measure rendered sheet height and use that value for FAB and map-control offsets.
- Remove visible map navigation title and position TopChrome/FilterChipBar by prototype constants.

## Questions

- `MemorySelectionState.swift` is not whitelisted, so measured sheet height should remain local to `MemoryMapHomeView` rather than added as `@Published` state.
- `project.yml` is not whitelisted and must not be regenerated in this stream; the operator will run xcodegen after merge.

## Counter / Review

- Risk: Velocity projection can skip from expanded directly to collapsed on very fast swipes. Mitigation: compute nearest projected snap, then limit one adjacent snap per gesture so UI tests and user intent remain stable.
- Risk: Adding visible strings for new controls could conflict with localization ownership. Mitigation: map controls are icon-only; only non-visible accessibility labels are added in this stream.

## Convergence

- Proceed with local `@State` sheet-height observation through a sheet binding because the `@Published` owner is outside the allowed file list.
- Use `interpolatingSpring(stiffness: 260, damping: 32)` as the initial tuning value requested by the directive.

## Decision

Implement Stream A within the explicit whitelist and stop before `xcodegen generate` or `xcodebuild`.

## Challenge Section

Normative decision: cap velocity-projected snap changes to one adjacent snap per release. This preserves nearest-snap calculation while avoiding prototype-inconsistent multi-snap jumps during high-velocity XCTest and real-user flicks.
