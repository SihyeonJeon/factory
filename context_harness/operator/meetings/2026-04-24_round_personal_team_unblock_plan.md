---
round: round_personal_team_unblock_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: r61-personal-team-unblock
contract_hash: d49d4d3c1be8336bbdcabef5b1a20fe229ca1a622209763bb1ed60713eb6db4f
---

## Context
- Personal Apple Developer team build is blocked by paid-only capabilities in entitlements.
- `UIBackgroundModes` belongs in Info.plist/project settings, not a custom entitlement key.
- Widget and Share Extension need explicit `DEVELOPMENT_TEAM` inheritance for command-line signing.
- Round contract limits implementation to three acceptances.

## Proposal
- Remove only the three unsupported entitlement keys from `App/MemoryMap.entitlements`.
- Add `DEVELOPMENT_TEAM: "$(DEVELOPMENT_TEAM)"` under the three app/extension target `settings.base` blocks.
- Add `PaidDeveloperFeatures` toggles and guard only the Sign in with Apple UI entry point.
- Leave `DeepLinkRouter` unchanged so custom scheme and existing unit-test https parsing remain stable.

## Questions
- None for this narrow round.

## Counter / Review
- Codex challenge: Do not disable the `https://unfading.app/memory|event` parser in `DeepLinkRouter` merely because Associated Domains are unavailable to a Personal Team. AASA absence prevents Universal Link invocation on device, while the pure parser is still covered by tests and should stay stable.
- Codex challenge: Do not remove R43 Apple Sign in implementation. The build unblock requires entitlement/UI gating only, preserving a one-line paid-team restoration path.

## Convergence
- Proceed with entitlement removal, target-level team inheritance, and UI-only paid feature gating.
- Verification scope is limited by local CoreSimulator/network availability; failed infrastructure start does not expand the round.

## Decision
- Narrow implementation accepted for `round_personal_team_unblock_r1` with exactly the three contract acceptances.

## Challenge Section
- Rejected broader remediation: removing Apple Sign in coordinator code, Supabase Apple auth wiring, or Universal Link parsing would exceed the round and increase paid-team reactivation cost.
- Risk retained intentionally: `associatedDomainsAvailable` is introduced for the future paid transition but is not used to gate parser tests in this round.
