# STAGE_CONTRACT — Harness v5

**Version:** v5.7
**Precedence:** 3rd (below round contract + REGULATION)
**Amend via:** Meeting + CHANGELOG bump

This document defines the stages of a round, who performs each, who cross-validates, the parallel-vs-serial pattern, and ownership of files/directories.

---

## §1. Stage Matrix

Every stage has exactly one **Performer** and one **Cross-Validator**. Self-approval forbidden.

The `stage_id` column is the canonical identifier used in meeting frontmatter, lock `stages_completed[]`, and `lint_config.toml`. Display names are human labels only — never cite them in frontmatter.

| # | stage_id | Display | Performer | Cross-Validator | Pattern | Artifact |
|---|----------|---------|-----------|----------------|---------|----------|
| 1 | `overall_planning` | Overall Planning | Claude Code + Codex (co-propose) | Human | Serial | `meetings/<round>_plan.md` |
| 2 | `detailed_design` | Detailed Design | Codex | Claude Code | Serial | `contracts/<round>/spec.md` |
| 3 | `convention_lock` | Convention / Linter Lock | Claude Code | Codex | Serial | `contracts/<round>/convention_version.txt`, `lint_config.txt` |
| 4 | `eval_protocol` | Eval Protocol Authoring | Codex | Claude Code | Serial | `contracts/<round>/eval_protocol.md` |
| 5 | `acceptance` | Acceptance Criteria | Codex | Claude Code | Serial | `contracts/<round>/acceptance.md` |
| 6 | `round_lock` | Round Lock Creation | Claude Code (runs checker) | Codex (reviews lock JSON) | Serial | `locks/<round>.lock` |
| 7 | `coding_1st` | Coding 1st Pass | **Codex (dispatched session)** (v5.7 change) | Codex (fresh session, author ≠ verifier across sessions) + Claude Code review oversight | Serial (one dispatch per sub-feature); parallel only with disjoint whitelists | Commit(s) + `meetings/<round>_review1.md` |
| 8 | `runtime_capture` | Runtime Evidence Capture | Claude Code (following §5 eval protocol) | Codex (reviews report completeness) | Parallel across screens/scenarios | `context_harness/reports/<round_id>/evidence/*` |
| 9 | `evaluation_verdict` | Evaluation Verdict | Codex | Claude Code (checks verdict is grounded in evidence) | Serial | `context_harness/reports/<round_id>/verdict.md` |
| 10 | `gate2` | Gate 2 Three-Evaluator | red_team_reviewer, hig_guardian, visual_qa (parallel fork) | Cross-agreement rule (Gate 3) | **Parallel** | `context_harness/reports/<round_id>/gate2/*` |
| 11 | `coding_2nd` | Coding 2nd Pass (remediation) | Codex + Claude Code (co-decide fix) → **Codex dispatched session** (v5.7 change) | Codex (fresh review session) | Serial | Commit(s) + `meetings/<round>_review2.md` |
| 12 | `retro` | Round Retro | Claude Code + Codex | Human | Serial | `round_retro/<round>.md` |
| 13 | `regulation_update` | Regulation Update (if any) | Proposer operator | Other operator | Serial | Amendment meeting + CHANGELOG |

Additional non-round stage_ids used in meeting frontmatter:
- `operator_amendment` — corrective edits to operator docs outside an active round
- `factual_verification` — purely factual/status-check meetings (no normative decision)

### Stage precedence within a round

Stages 1–6 must complete before stage 7 begins. Stage 7–11 may interleave with amendment meetings. Stage 12 only after all Gate 1–5 pass. Stage 13 is optional and triggered only if retro identifies regulation debt.

## §2. Parallel vs Serial Rules

**Parallel permitted when:**
- Independent evidence gathering across disjoint screens/scenarios (stage 8)
- Gate 2 three-evaluator fork (stage 10) — dedicated role contracts, no shared state
- Implementation across disjoint `file_whitelist` partitions AND separate worktrees

**Serial required when:**
- Contract-setting (stages 2–6): sequential review preserves authorship attribution
- Approval/merge decisions: single authoritative decision trail
- Amendment meetings: one amendment committed before the next begins

**Forbidden parallel:**
- Two operators editing the same file concurrently (use meeting + whitelist partition)
- Performer and cross-validator swapping mid-stage (breaks author/verifier separation)
- Parallel evaluation without a locked rubric (stage 8 must follow locked eval_protocol)

## §3. Ownership Zones

Default ownership determines who drafts without a meeting. Crossing zones requires a meeting + whitelist expansion.

### Codex Operator — default owner (v5.7 widened to include Swift)

- `operator/contracts/<round>/spec.md` and amendments
- `operator/contracts/<round>/acceptance.md`
- `operator/contracts/<round>/eval_protocol.md`
- `context_harness/reports/<round_id>/verdict.md`
- `docs/design-docs/ios-architecture.md` (architecture-level edits)
- `docs/product-specs/*` (acceptance criteria docs)
- `AGENTS.md` invocation notes (persona section only; shared body requires meeting)
- **`workspace/ios/**/*.swift` (moved from Claude Code in v5.7)** — all Swift source. Author session ≠ reviewer session (different `codex exec` calls).

### Claude Code Operator — default owner (v5.7 narrowed — no Swift)

- ~~`workspace/ios/**/*.swift`~~ — MOVED to Codex owner in v5.7.
- `workspace/ios/project.yml`, `Package.swift` (non-Swift project structure)
- `operator/contracts/<round>/file_whitelist.txt`
- `operator/contracts/<round>/convention_version.txt`
- `operator/contracts/<round>/lint_config.txt`
- `context_harness/handoffs/<round>*.md` (implementation briefs = dispatch prompts to Codex)
- `context_harness/reports/<round_id>/evidence/*` (runtime capture outputs — evidence, not verdict)
- `.claude/CLAUDE.md` invocation notes (persona section only; shared body requires meeting)
- `harness/*.py` (orchestration infrastructure — non-Swift)

### Shared — meeting-gated

- `operator/OPERATOR.md`, `operator/REGULATION.md`, `operator/STAGE_CONTRACT.md`, `operator/MEETING_PROTOCOL.md`, `operator/PROCESS_AUDIT_CHECKLIST.md`
- `operator/FILE_INDEX.md` (any addition must reference the file's existence)
- `operator/CHANGELOG.md`
- `operator/lint_config.toml`
- Body of `AGENTS.md` and `.claude/CLAUDE.md` outside their persona-notes sections
- `SKILLS.md` and `SECURITY.md`
- `SESSION_RESUME.md` — live state snapshot (not meeting-gated per Codex R3), but contradictions caught by drift audit

### Human — sole owner

- `docs/product-specs/hf-round*-acceptance.md` headers and sign-off
- Any file explicitly marked "USER ONLY" in its header
- Release/tag operations

## §4. Zone Crossing Protocol

When a task requires editing a file outside your default zone:

1. Open a meeting with subject "Zone crossing: <file>"
2. Record reason, scope of edit, reversibility
3. Peer reviews — approves, proposes alternative, or declines
4. On approval: expand `file_whitelist.txt` via amendment (§REGULATION §3)
5. Perform edit → peer reviews output → close meeting

Shortcut not permitted: you cannot edit first and open meeting after. Caught by Gate 5 drift audit (lock hash mismatch).

## §5. Evidence ≠ Verdict Rule

Specific to stage 8 → stage 9 boundary.

**Claude Code (evidence capture):**
- Follows locked `eval_protocol.md` verbatim
- Produces: raw observations, command output, screenshot paths, simulator/device metadata, timestamps, app state notes
- Forbidden language in capture report: "PASS", "BLOCKER", "ADVISORY", "good", "bad", "acceptable", "regression"
- Permitted language: "screenshot X shows Y", "command Z returned exit W", "element A was/wasn't present"
- Protocol gaps found during capture → stop, open amendment meeting OR mark "capture exception" section with the gap for Codex to address in verdict

**Codex (verdict authoring):**
- Reads evidence report + locked rubric
- Writes interpretation: PASS/BLOCKER/ADVISORY with specific evidence citations
- May request additional capture if evidence is insufficient (goes back to stage 8 with an amendment)

## §6. Gate Owners

| Gate | Runs | Owner |
|------|------|-------|
| 1 | `xcodegen generate && xcodebuild test` | Claude Code |
| 2 | 3-evaluator fork | Harness (parallel subagents) |
| 3 | Cross-agreement check | Codex (reads all 3 reports) |
| 4 | Process metrics from process-log | Codex |
| 5 | `harness/check_operator_round.py gates <round>` | Checker (run by either operator; output reviewed by the cross-validator of the stage being closed) |

---

**Read next:** `MEETING_PROTOCOL.md` for meeting file template and rules.
