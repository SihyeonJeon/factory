---
round: round_foundation_reset_r1
stage: overall_planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round2-foundation-reset-plan
contract_hash: none
created_at: 2026-04-23T00:10:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
codex_transcript: context_harness/operator/codex_transcripts/codex_round2_plan.log
---

# Meeting — Round 2 Plan: `round_foundation_reset_r1`

**Purpose:** Kick off implementation rounds for the Unfading UI/UX redesign. Round 1 produced contract-only analysis (tokens/gap/slicing). This round must confront a bigger gap than round 1 foresaw and establish the reusable-asset foundation every subsequent slice will compose against.

**Chair:** Claude Code Operator
**Peer:** Codex Operator (same session)
**User directive (2026-04-23):** dual-operator harness + spec/convention/governance/linter compliance + code-as-reusable-assets + autonomous cross-validation loop. Docs-vs-code gap predates these rules; fix via harness loop.

## Context — real-state discovery (authoritative)

Targeted inspection of `workspace/ios/` today shows the actual app is at MVP scale, not at the advanced state SESSION_RESUME.md narrates. Facts:

- **12 Swift files, 1,135 lines total (including tests).** Not the Sprint 51 140-test history.
- **10 tests** in `Tests/MemoryMapTests.swift`, not 140.
- **3 tabs** (Map / Rewind / Groups) in `RootTabView.swift`. No Calendar, no Settings, no Memory Detail, no archive.
- **No `UnfadingTheme`** anywhere; code uses `Color.accentColor` and inline `Color.white.opacity(...)`.
- **No Korean** in Swift source; tab labels literal `"Map"`, `"Rewind"`, `"Groups"`.
- **`workspace/` gitignored** — Swift changes won't appear in git commit traceability; governance audit will be evidence-hash based, not git-diff based.

`docs/references/coding-conventions.md`, `docs/design-docs/ios-architecture.md`, and `SKILLS.md` S-17 all describe governance that the actual code violates from day one. Round 1's verdict advisory #2 (UnfadingTheme missing) was the tip of this iceberg.

Raw deepsight inputs at `docs/design-docs/unfading_design/` are SHA-identical to `docs/design-docs/travel_deepsight/` (verified via `shasum`). The user renamed/relocated; content is unchanged. Round 1 analysis artifacts (`deepsight_tokens.md`, `deepsight_gap_analysis.md`, `deepsight_slicing_manifest.md`) remain valid inputs for planning.

## Proposal — round 2 scope

**Name:** `round_foundation_reset_r1`
**Type:** implementation (Swift + operator doc reconciliation)
**Principle:** build reusable modules, not one-shot features. Each module must be importable and composable by future screen/navigation slices without modification.

### Deliverables (reusable assets)

1. **`workspace/ios/Shared/UnfadingTheme.swift`** — canonical token namespace. Namespaces: `UnfadingTheme.Color`, `.Font`, `.Radius`, `.Spacing`, `.Sheet` (snap points). Values from `deepsight_tokens.md`. No colors defined anywhere else.
2. **`workspace/ios/Shared/UnfadingLocalized.swift`** (or `Localizable.xcstrings` sidecar) — Korean string keys for current UI (3 tabs + navigation titles + existing MemoryComposerSheet). Establishes `String(localized:)` pattern.
3. **`workspace/ios/Shared/UnfadingButtonStyle.swift`** — reusable press style (coral primary fill + press feedback) per deepsight component observations.
4. **`workspace/ios/Shared/UnfadingCardBackground.swift`** — reusable card surface (cream/warm + radius 20 + subtle shadow).
5. **Refactors (minimum viable)** to use the new modules:
   - `RootTabView.swift`: tab labels → Korean via `UnfadingLocalized`; tint → `UnfadingTheme.Color.primary`
   - `MemoryMapHomeView.swift`, `MemoryComposerSheet.swift`, `MemorySummaryCard.swift`: replace inline `Color.accentColor` / `Color.white.opacity(...)` with `UnfadingTheme.Color.*`
6. **Test additions** exercising the new modules:
   - `UnfadingThemeTests.swift` — asserts key token values (coral hex, radii) and non-empty localizations
   - Target: 10 baseline → ≥ 18 tests after this round
7. **Doc reconciliation:**
   - `SESSION_RESUME.md` — truthful "Reality Baseline" section replacing the Sprint 51 narrative; old narrative moved to `docs/exec-plans/sprint-history-pre-v5.md` as an explicitly-labeled archive
   - `docs/references/coding-conventions.md` — amendment-style note that `UnfadingTheme` began this round and prior inline-color rules applied only post-v5.6
   - `SKILLS.md` S-17 — clarify that the checklist is forward-looking, pre-round-2 code did not comply
8. **Governance decision:**
   - Decide whether to un-gitignore `workspace/` so Swift changes land in git (makes commit traceability real) OR keep gitignored with evidence-manifest audit

### Non-goals (explicitly deferred)

- New screens (Calendar / Settings / MemoryDetail / archive) — future rounds
- Navigation restructure (still 3 tabs this round; 5-tab deepsight layout is a later slice)
- Map redesign beyond token swap
- Rewind / Groups feature expansion
- MemoryComposer restructure (only color/string surface refactor)

## Questions for Codex

**Q1 — Scope.** Is this the right first implementation round? Alternatives: (a) even smaller (theme-only, no localization), (b) this proposal, (c) include one screen redesign. I lean (b). Your take?

**Q2 — Reusable-asset unit.** The user explicitly said "재사용 가능한 자산/에셋 단위로 코딩." How granular should modules be? My proposal: one file per module (Theme / Localized / ButtonStyle / CardBackground). Should we split further (e.g., separate `UnfadingColors.swift` from `UnfadingRadii.swift`) or combine? Trade-off: file count vs cohesion.

**Q3 — Korean localization mechanism.** `Localizable.xcstrings` (SwiftUI 5.9+ native, tooling-supported) vs a plain Swift namespace `UnfadingLocalized.tabMap = "지도"`. Plain Swift is simpler for v1; xcstrings scales to future localization. I lean plain Swift namespace for this round, xcstrings migration as a later slice if we ever need multi-locale. Counter?

**Q4 — gitignore decision.** `workspace/` is currently gitignored. Commit traceability doesn't see Swift changes. Options: (a) remove `workspace/` from .gitignore so round commits actually prove Swift landed; (b) keep gitignored, require `gate_evidence.json` to include an `output_artifacts` array with Swift file paths + SHAs for every implementation round. I lean (a) — un-gitignore now, before the repo gets too big. Governance much tighter. Your view?

**Q5 — Doc reconciliation discipline.** SESSION_RESUME has been carrying forward false history. The clean fix is: truthful rewrite of current state + archive of prior narrative labeled clearly. Any objection to that approach, or do you prefer a less destructive reconciliation (e.g., preamble noting "pre-v5 narrative below" without rewriting)?

**Q6 — Round acceptance criteria teeth.** I want specific, checkable acceptance:
- Zero `Color.white`, `Color.black`, `Color.accentColor`, `Color(red:...)` outside `UnfadingTheme.swift`
- Zero literal English strings in `*View.swift` files except identifiers
- All 5 modules exist and are imported at least once
- Tests ≥ 18 and all pass
- `UnfadingTheme.Color.coral` sha-stable value matching `deepsight_tokens.md` Coral `#F5998C`
Any additions or concerns?

**Q7 — Linter.** Round 1 linter scope was operator docs only (not Swift). This round introduces reusable Swift modules. Do we expand `lint_config.toml` to cover Swift conventions NOW (e.g., forbidden `Color.white` check via grep pattern) or defer to a v5.7 amendment? I lean: add a minimal grep-based Swift lint in this round's acceptance, full Swift linting deferred.

**Q8 — Cross-validation pattern.** Per user directive, Codex and I cross-validate. Suggested per-slice split:
- Spec/acceptance/eval_protocol: Codex authors, Claude Code reviews
- Swift implementation: Claude Code authors, Codex code-review
- Evidence capture: Claude Code (factual only)
- Verdict: Codex
Agree or rebalance?

Respond with:
- position on Q1-Q8
- any dependency you'd insert (e.g., "do X before Y")
- any Open Question the gap analysis raised that we must resolve BEFORE this round (e.g., Calendar placement, map palette, UnfadingTheme strategy)

If converged: I'll update meeting status to decided, you author spec/acceptance/eval_protocol, I author whitelist/convention/lint pointers, lock, then iterate the implementation stages.

## Counter / Review

Codex R-round2 (transcript: `operator/codex_transcripts/codex_round2_plan.log`):
- Q1 AGREE foundation+refactor+localization; no screen redesign
- Q2 AGREE one file per module, UnfadingTheme keeps nested namespaces
- Q3 AGREE plain Swift `UnfadingLocalized`; defer xcstrings
- **Q4 COUNTER**: selective un-gitignore, NOT blanket. Un-ignore `workspace/ios/{App,Features,Shared,Tests}/**` + `workspace/ios/project.yml`; keep `*.xcodeproj/`, `.build/`, `.deriveddata/` ignored
- Q5 AGREE truthful SESSION_RESUME rewrite + archive old narrative
- Q6 AGREE with refinements: "English strings" = user-facing SwiftUI Text/accessibility only (not systemImage/enum/test names); grep checks on touched view files; whole-workspace if scope allows
- Q7 AGREE minimal grep-based Swift lint now; no full `lint_config.toml` Swift expansion yet
- Q8 AGREE ownership split
- **Dependency inserted**: decide/commit `workspace/` tracking policy BEFORE Swift implementation starts
- **9th must-address**: every reusable module must be used by ≥1 production Swift file AND ≥1 test, else risk "nominal assets future slices ignore"

## Convergence

Full convergence on all 9 items. Codex's Q4 refinement adopted. Gitignore update applied before meeting closure (visible in current `.gitignore`):
- `workspace/*` + `!workspace/ios/` pattern
- `workspace/ios/*` + allow-list for App/Features/Shared/Tests + project.yml
- Explicit re-ignore of xcodeproj/.build/.deriveddata

## Decision

**round_foundation_reset_r1** approved as described. Scope: foundation + refactor + Korean localization; reusable assets pattern; SESSION_RESUME truthful rewrite + pre-v5 narrative archived. No new screens.

Deliverables locked:

**Reusable modules** (each must be imported by ≥1 production file + ≥1 test per Codex #9):
- `workspace/ios/Shared/UnfadingTheme.swift`
- `workspace/ios/Shared/UnfadingLocalized.swift`
- `workspace/ios/Shared/UnfadingButtonStyle.swift`
- `workspace/ios/Shared/UnfadingCardBackground.swift`

**Refactors** (touched view files must use new modules, drop inline colors/English):
- `RootTabView.swift`, `MemoryMapHomeView.swift`, `MemoryComposerSheet.swift`, `MemorySummaryCard.swift`, `MemoryPinMarker.swift`

**Tests** (baseline 10 → target ≥18):
- `UnfadingThemeTests.swift` — token values + non-empty localizations + each reusable module used in at least one unit test

**Doc reconciliation**:
- `SESSION_RESUME.md` truthful rewrite
- `docs/exec-plans/sprint-history-pre-v5.md` — archive of prior narrative
- `docs/references/coding-conventions.md` — amendment note on pre-round-2 non-compliance
- `SKILLS.md` S-17 — forward-looking scope note

**Governance**:
- `.gitignore` selective un-gitignore applied ← dependency satisfied pre-lock
- Gate 2 "reports" for this round = Codex code-review artifact + refactor-surface grep scan + test pass log (no external 3-evaluator fork since it's implementation, not visual QA)

## Challenge Section

### Objection
User directive emphasized "재사용 가능한 자산/에셋 단위". Codex's 9th item (each module must be imported by ≥1 production + ≥1 test) is the concrete operationalization. Risk this becomes box-checking rather than genuine reuse. Mitigation: acceptance criterion requires BOTH production import AND test import; review will check that usage is substantive (not just `_ = UnfadingTheme.Color.coral`).

### Risk
`workspace/ios/` tracking change triggers thousands of lines becoming first-class git history in one commit. Diff will be large. Mitigation: commit the infrastructural gitignore+initial-track as its own pre-round commit so round 2's diff stays scoped to additions/refactors.

### Rejected alternative
- **Screen redesign included in round 2.** Rejected because it tangles refactor with token rollout; would bloat the diff and muddy acceptance criteria.
- **xcstrings localization from day one.** Rejected because single-locale project; adds build complexity without payoff; can migrate later if multi-locale needed.
- **Full Swift linter in v5.7.** Rejected because operator `check_operator_round.py` is heavy enough; grep-based acceptance gates provide sufficient discipline for now.

### Uncertainty deferred
- Exact Korean strings for non-trivial UI (e.g., composer labels) — Codex will author first cut in spec.md, Claude Code may revise during implementation with evidence note for any deviation
- Whether `MemoryComposerSheet` should keep its large surface unchanged (minimal color/string refactor) or get restructured — defer full restructure to a future Composer slice
- Whether tests should target `@MainActor` on new modules — defer to Codex's spec.md

## Amendment Detail

Not an amendment — planning decision. Subsequent amendments to the round's base contract (spec/acceptance/eval_protocol/whitelist) after lock will use `cmd_amend` per v5.5 flow.
