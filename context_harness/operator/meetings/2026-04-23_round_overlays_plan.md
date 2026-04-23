---
round: round_overlays_r1
stage: coding_1st
status: draft
participants: [codex]
decision_id: r30-overlays-plan
contract_hash: none
---

## Context
- Contract source: `context_harness/operator/contracts/round_overlays_r1/spec.md`.
- Visual source: `docs/design-docs/unfading_ref/design_handoff_unfading/README.md` sections 3 and 4.
- Implementation surface: `UnfadingTabShell` owns modal visibility; `MemoryMapHomeView` exposes TopChrome and filter-plus callbacks.
- Active group state remains in `GroupStore`; custom category state is local persisted app state via `CategoryStore`.

## Proposal
- Implement both overlays as full-frame SwiftUI `.overlay` content with internal `ZStack`, themed translucent backdrop, material blur, and fixed-width cards.
- Add `CategoryStore.shared` with UserDefaults JSON persistence under `unf.categories`.
- Keep the group creation button wired to existing `GroupOnboardingView`; no new create flow is authored in this round.
- UI tests use deterministic DEBUG group stubs with two groups.

## Questions
- Lock file was not present at `context_harness/operator/locks/round_overlays_r1.lock`; proceed using the round contract and user dispatch as authority.

## Counter / Review
- Challenge: `.sheet` would give native dismissal and accessibility behavior, but cannot match the README backdrop/card composition or simultaneous z-index ordering without fighting the system presentation.
- Challenge: using `Color.black.opacity(0.28)` literally would match the prose, but violates current token discipline. The implementation uses `UnfadingTheme.Color.overlayBackdrop`, derived from the existing text-primary ink color at 28% opacity.
- Risk: inactive group rows cannot show real member rosters until the repository supports per-group member prefetch; fallback initials preserve layout fidelity.

## Convergence
- Use `.overlay` + `ZStack`, not native `.sheet`, for both overlays.
- Shell state enforces one overlay at a time by closing the other overlay on presentation.
- Duplicate category names throw from the store and are surfaced inline in the editor.

## Decision
- Proceed with implementation in the whitelist above.

## Challenge Section
- Rejected alternative: keep hard-coded filter chips and only use `CategoryStore` inside the editor. This would satisfy persistence but fail the README intent that user categories appear in the home filter row.
- Rejected alternative: leave TopChrome opening `GroupHubView` and add the picker elsewhere. This would miss the contract trigger and keep the old settings-oriented interaction on the map chrome.
