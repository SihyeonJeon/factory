---
round: round_deepsight_r1
stage: overall_planning
status: decided
participants: [claude_code, codex]
decision_id: 20260422-round1-deepsight-plan
contract_hash: none
created_at: 2026-04-22T20:15:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
codex_transcript: context_harness/operator/codex_transcripts/codex_round1_plan.log
---

# Meeting — Round 1 Plan: `round_deepsight_r1`

**Purpose:** Stop iterating on the harness. Use `round_deepsight_r1` as a real stress-test. Verify which of your 8 flow-hole blockers actually manifest when legitimate round work is attempted, and fix only those.

**Chair:** Claude Code Operator
**Peer:** Codex Operator (same session)

## Context

- v5.3 committed at `c43d6c5` with 8 flow-hole blockers flagged by stop-hook (your R5 review).
- User directive: run a real round, observe which Codex blockers are real, fix by evidence.
- Deepsight input: `docs/design-docs/travel_deepsight/` (HTML prototype, 2 PNGs, 8-screen revision).
- Per kickoff Q6 slicing: token → nav → screen clusters → a11y sweep.

## Proposal

**Round 1 scope = design token extraction + gap analysis + slicing manifest.** 
NO Swift code changes in this round. NO sprint implementation. This is a CONTRACT-ONLY round whose deliverables are the input for subsequent coding rounds.

Why:
- First real round exercises the v5 harness without putting product code at risk.
- Produces the tokens/conventions that later sprints lock against.
- Naturally small; if the harness breaks, the failure is contained.
- Contract-only means `gate1` (build/test) requires no change — test count stays 140.

### Proposed deliverables (all under `context_harness/operator/contracts/round_deepsight_r1/`)

1. `spec.md` — formal description of what round 1 produces, not what the app will look like
2. `file_whitelist.txt` — empty or limited to `docs/design-docs/deepsight_tokens.md` + `docs/design-docs/deepsight_gap_analysis.md`
3. `convention_version.txt` — pointer to current `coding-conventions.md` SHA
4. `lint_config.txt` — pointer to current `operator/lint_config.toml` SHA
5. `acceptance.md` — deliverables + success criteria
6. `eval_protocol.md` — you author this (per STAGE_CONTRACT stage 4); capture protocol for reviewing the round outputs

## Questions

Q1. Is a **contract-only** first round the right choice, or should we include a token-sprint (one-screen worth of Swift) to exercise `gate_evidence.json` end-to-end?

Q2. For `file_whitelist.txt`: do we include the deepsight zip itself (already committed) or write new docs under `docs/design-docs/deepsight_*.md`? I lean the latter — keep raw inputs read-only, write analysis as new docs.

Q3. Expected v5.3 flow breakpoints I want to probe:
- **Your blocker #1** (no amend command): likely hits if we need to expand whitelist mid-round
- **Your blocker #5** (schema_version not enforced): won't hit in a fresh round
- **Your blocker #10** (no paused/escalated cmd): only hits if deadlock escalation triggers
  
Which blockers do you predict will **actually** break vs. stay theoretical in this contract-only round?

Q4. You author `eval_protocol.md`. Please outline what you'd put in it for a contract-only round — I want minimal viable eval_protocol, not a full runtime-capture spec.

Q5. Any risk that a contract-only round can't pass `close` because `gate_evidence.json` requires Gate 1 (build/test) command output even though no code changed? If so, my proposal: Gate 1 evidence = `exit_code: 0, test_count: 140, command: "xcodebuild test (no changes; pre-lock baseline)", log: (path to existing xcode_test.log + sha)`. Acceptable or does this violate the spirit of gate_evidence?

## Counter / Review

(Codex R6 — `/tmp/codex_round1_plan.log` / `codex_transcripts/codex_round1_plan.log`)

- **Q1:** contract-only is correct; no Swift in round 1. Mixing Swift now conflates harness validation with Xcode/runtime noise.
- **Q2:** write new analysis docs; do NOT modify the raw zip. Whitelist must be broader than just `docs/design-docs/deepsight_*.md` — commit traceability will fail if governance artifacts (lock, events, reports, process-log) aren't whitelisted.
- **Q3 predictions:**
  - **Sure to hit:** commit traceability if whitelist is too narrow (governance files get touched)
  - **Likely to hit if scope expands:** blocker #1 (no `amend` command)
  - **Likely NOT to hit this round:** schema_version, paused/escalated, manual close, stale identity, event sequence
  - **Post-close evidence hash hole:** won't block the round but we should run `gates` once after close to confirm it passes even if `gate_evidence.json` is edited (that directly confirms hole #4)
- **Q4:** proposed eval_protocol outline (inputs, evidence capture checklist, verdict split). Accepts I'll call it out as "factual observations only, no PASS/BLOCKER in evidence" — Codex writes verdict separately.
- **Q5:** baseline reuse is OK as long as `command` field explicitly labels `"baseline_reuse_no_code_round"`, not a faked xcodebuild invocation. Include git-untouched proof for `workspace/ios/`.

## Convergence

All 5 questions answered; no disagreement. Adopted Codex's proposed whitelist pattern verbatim.

## Decision

**round_deepsight_r1 = contract-only round.** Scope:

1. **Deliverables** (under `docs/design-docs/`):
   - `deepsight_tokens.md` — extracted design tokens (color, typography, spacing, radius)
   - `deepsight_gap_analysis.md` — current vs new inventory per `design-revision-workflow.md` Phase 1 table
   - `deepsight_slicing_manifest.md` — proposed sprint slices per Phase 3 order (token → nav → screen clusters → a11y sweep)

2. **Contract files** at `context_harness/operator/contracts/round_deepsight_r1/`:
   - `spec.md` — Codex authors (stage 2 detailed_design)
   - `file_whitelist.txt` — Claude Code authors (stage 3 convention_lock), using Codex's 9-line pattern
   - `convention_version.txt` — pointer to `docs/references/coding-conventions.md` + current SHA
   - `lint_config.txt` — pointer to `context_harness/operator/lint_config.toml` + current SHA
   - `acceptance.md` — Codex authors (stage 5)
   - `eval_protocol.md` — Codex authors (stage 4) per Q4 outline

3. **Lock** via `harness/check_operator_round.py lock round_deepsight_r1`; event log auto-created.

4. **Implementation:** generate the 3 deepsight docs following the locked spec + eval_protocol.

5. **Evidence capture:** factual observations into `context_harness/reports/round_deepsight_r1/evidence/contract_capture.md` per eval_protocol; no verdict language.

6. **Verdict:** Codex writes `context_harness/reports/round_deepsight_r1/verdict.md`.

7. **Close:** after running `gates` to verify integrity, execute `close round_deepsight_r1` with `gate_evidence.json` using baseline_reuse semantics for gate1.

**Triage logs:** throughout execution, log every v5.3 checker friction at `context_harness/reports/round_deepsight_r1/evidence/checker_friction.md` for post-round retro — this is how we decide which of Codex's 8 flow-hole blockers are real vs theoretical.

## Challenge Section

### Risk
Contract-only round doesn't exercise the code path that matters most for real product work (Swift implementation). Mitigation: accept this risk because round 1's goal is HARNESS validation, not product validation. Round 2 will include Swift and will surface any Swift-path holes.

### Rejected alternative
Including a tiny Swift change (e.g., add one token to `UnfadingTheme.swift`) to exercise gate_evidence end-to-end. Rejected per Codex R6 Q1: mixes harness validation with Xcode/runtime noise. Cleaner to validate harness first, then add Swift in round 2.

### Uncertainty deferred
We don't yet know what `command` value for Gate 1 evidence means across rounds. For round 1 it's `"baseline_reuse_no_code_round"`. Round 2 will be first real xcodebuild evidence; stress-test then.

### Objection
None substantive; Codex and I converged on all Q1-Q5 quickly. This is a contract-setting meeting, not a controversial normative decision.

## Amendment Detail

N/A — planning meeting.

