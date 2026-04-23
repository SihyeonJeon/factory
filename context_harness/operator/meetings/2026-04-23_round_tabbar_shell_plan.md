---
round: round_tabbar_shell_r1
stage: coding_1st
status: decided
participants: [codex]
decision_id: 20260423-r27-tabbar-shell
contract_hash: 12796ec5f6a83327dafa36c76786ca71347c7236b7ccfbeb91a84a0434708092
---
# R27 Custom Tab Shell Plan

## Context
- Source contract: `context_harness/operator/contracts/round_tabbar_shell_r1/spec.md`.
- Design authority: `docs/design-docs/unfading_ref/design_handoff_unfading/README.md`.
- R27 replaces native 5-tab `TabView` with a custom 3-tab root ZStack.
- Composer moves from compose-tab interception to a home-only FAB.
- Rewind moves from top-level tab to a home curation card.

## Proposal
- Add `UnfadingTabShell` under `workspace/ios/App/` with `ShellTab.map/calendar/settings`.
- Reduce `RootTabView` to a compatibility wrapper around `UnfadingTabShell`.
- Add `ComposeFAB` under `Features/Home/` and present `MemoryComposerSheet` from the shell with `fullScreenCover`.
- Remove the old home-owned FAB and composer sheet from `MemoryMapHomeView`.
- Add a Rewind hint card to `MemorySummaryCard` and route it through `MemoryMapHomeView` to `RewindFeedView`.
- Migrate UI tests from native `tabBars` lookup to stable button identifiers.

## Questions
- None requiring product escalation. The contract already accepts the R28 deferral for bottom-sheet behavior.

## Counter / Review
- Risk: moving composer presentation out of `MemoryMapHomeView` could break evidence mode. Mitigation: shell owns the same `evidenceMode` and auto-presents once when non-`.none`.
- Risk: fixed 83pt tab bar can cover content in non-map tabs. This is accepted by the design handoff for R27; later screen-specific bottom padding can be addressed per-feature if needed.
- Risk: Rewind hint visibility conditioned on month-end could make UITest flaky. Mitigation: DEBUG UI-test environment forces the hint on.

## Convergence
- Use raw-value identifiers (`tab-map`, `tab-calendar`, `tab-settings`) per dispatch instruction.
- Preserve `UnfadingLocalized.Tab.compose` and `.rewind` for backward compatibility while excluding them from the visible shell.
- Skip `testMapBottomSheetSnapGestures` with an explicit R28 note instead of asserting current broken sheet behavior.

## Decision
- Implement the custom shell and test migration in R27.
- Defer bottom-sheet snap/expanded behavior to R28.

## Challenge Section
- Objection considered: keeping native `TabView` and hiding two tabs would preserve existing tests, but it would not satisfy the required zIndex 120 custom shell or prepare the shared root ZStack for R28.
- Objection considered: keeping Rewind as a hidden tab destination would retain old navigation semantics, but the authoritative state model has only `map/calendar/settings` tabs.
- Rejected alternative: put the FAB back inside `MemoryMapHomeView` and raise its zIndex. That keeps presentation ownership split across nested NavigationStack layers and weakens the R28 sheet/FAB coordination path.
