---
round: round_design_tokens_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r26-tokens
contract_hash: 9646c0b2e4106070c0c1ed28782a98a2d81574593477c656177ba96582efbc58
---
# R26 Design Tokens + Font Bundle Plan

## Context
- Contract: `context_harness/operator/contracts/round_design_tokens_r1/spec.md`.
- Authority source: `docs/design-docs/unfading_ref/design_handoff_unfading/README.md`.
- Scope is token/font alignment only; component layout redesign belongs to R27+.
- Font files are already present in `workspace/ios/App/Fonts/` with verified PostScript names.
- Active lock file was not present at `context_harness/operator/locks/round_design_tokens_r1.lock` during this coding session.

## Proposal
- Rewrite `UnfadingTheme` with README colors, radius, spacing, shadows, custom font helpers, member palette, and 0.08/0.50/1.0 sheet snap token values.
- Register `App/Fonts` and `UIAppFonts` in `workspace/ios/project.yml`; keep `App/Info.plist` free of direct `UIAppFonts` duplication.
- Replace direct `.font(.system(...))` and `Font.system(...)` UI surface usage under `App`, `Features`, and `Shared`.
- Add `UnfadingFontLoadingTests` to assert Gowun Dodum and Nunito names load without falling back to system fonts.
- Update token-facing tests that still asserted R24 values so all tests reflect the R26 design handoff.

## Questions
- None for implementation. The README resolves the known prototype-vs-handoff snap conflict in favor of 0.08/0.50/1.0.

## Counter / Review
- Pending verifier session. Author notes: this session modified code and therefore cannot self-approve the round.

## Convergence
- Coding uses the supplied contract and README as the source of truth.
- The missing lock file is recorded as evidence for gate handling by the operator layer.

## Decision
- Proceed with R26 token/font implementation exactly within the supplied scope.

## Challenge Section

### Objections
- `UIFont(name:)` tests can fail if the Xcode project does not host unit tests inside the app bundle where `UIAppFonts` is applied. This should be caught by `xcodebuild test`; if it occurs, the fix is project configuration, not loosening the assertions.
- Applying custom `SwiftUI.Font` to SF Symbol `Image` views removes direct system-font calls but may alter symbol sizing behavior. The affected calls are only two place-picker icons and should be visually checked in R26/R27 smoke.

### Risks
- `Spacing.xs/sm/md/lg/xl` now follow the README scale, so existing surfaces using old aliases will gain whitespace. This is acceptable for a token realignment round but should be noted in visual review.
- Gowun Dodum is a single-weight face; compatibility helpers like `subheadlineSemibold()` cannot create a true bold variant without falling back to system fonts.

### Rejected Alt
- Keeping old spacing aliases at their previous numeric values. Rejected because it preserves R24 drift and makes the README scale ambiguous.
- Registering `UIAppFonts` in both `project.yml` and `App/Info.plist`. Rejected to avoid duplicate sources of truth; `project.yml info.properties` generates the app Info values.
