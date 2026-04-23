---
round: round_group_hub_settings_r1
stage: implementation
status: decided
participants: [codex]
decision_id: r35-group-hub-settings
contract_hash: none
---

## Context

- Human requested R35 Group Hub settings implementation in a fresh Codex session.
- Design source: `docs/design-docs/unfading_ref/design_handoff_unfading/README.md` section 9.
- Existing Settings row used a Button/sheet pattern that kept `testGroupHubFromSettings` skipped.

## Proposal

- Use `NavigationLink` from Settings to Group Hub to avoid SwiftUI Form/Button identifier issues.
- Keep Group Hub backend-neutral for leave/delete/export/QR while wiring the expected UI, toggles, and confirmation state.
- Reuse `GroupPickerOverlay` for "다른 그룹으로 전환".

## Counter / Review

- No peer operator review was performed in this turn.
- Risk: `xcodebuild test` execution is blocked in this sandbox by CoreSimulatorService and package/cache write restrictions; local project generation succeeded.

## Convergence

- Implemented within the requested file scope plus required artifacts.

## Decision

- Proceed with R35 UI/test changes and report environment-limited verification.

## Challenge Section

- No normative peer dissent was fabricated. Residual risk is runtime verification: UI navigation and UITest reactivation need a normal simulator/Xcode environment to execute.
