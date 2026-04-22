# FILE_INDEX — Harness v5

**Purpose:** use-case → exact file pointer. Replaces bulk directory scanning.
**Line cap:** ≤250 lines. When approaching, split into topic sub-indexes under `operator/indexes/`.
**Rule:** opening a file NOT listed here is permitted but must be logged one line in `context_harness/blackboard.md` with reason. If the file should have been here, amend.

---

## Starting a session

- Your persona loader: `.claude/CLAUDE.md` (Claude Code) or `AGENTS.md` (Codex)
- Shared persona/principles: `context_harness/operator/OPERATOR.md`
- This file: `context_harness/operator/FILE_INDEX.md`
- Current state snapshot: `context_harness/SESSION_RESUME.md`
- Active round (if any): `context_harness/operator/locks/<round_id>.lock`

## Regulation and authority

- Top-level regulation (precedence, lock schema, immutability): `context_harness/operator/REGULATION.md`
- Stage matrix, ownership, parallel/serial rules: `context_harness/operator/STAGE_CONTRACT.md`
- Meeting template and Challenge Section rule: `context_harness/operator/MEETING_PROTOCOL.md`
- Gate 5 checklist: `context_harness/operator/PROCESS_AUDIT_CHECKLIST.md`
- Version history of operator docs: `context_harness/operator/CHANGELOG.md`

## Starting or joining a round

- Create a round: `context_harness/operator/contracts/<round_id>/` with `spec.md`, `file_whitelist.txt`, `convention_version.txt`, `lint_config.txt`, `acceptance.md`, `eval_protocol.md`
- Lock schema and immutability rules: `REGULATION.md §3`
- Round retro template: `PROCESS_AUDIT_CHECKLIST.md`

## Writing a meeting

- Template: `context_harness/operator/meetings/_template.md`
- Existing meetings: `context_harness/operator/meetings/<ISO>_<topic>.md`
- Codex session transcripts (persist for tamper-evidence): `context_harness/operator/codex_transcripts/`
- Process log (append JSONL on decided): `docs/exec-plans/process-log.jsonl`
- Lock event log (per-round append-only, tamper-evident): `context_harness/operator/locks/<round_id>.events.jsonl`

## Running the checker

- Script: `harness/check_operator_round.py`
- Lint config (operator-doc scope, TOML): `context_harness/operator/lint_config.toml`
- Checker commands: `lint` | `lock <round>` | `amend <round> <file> <meeting>` | `gates <round>` | `close <round>` | `audit-operator-layer`
- Process log (append-only JSONL, one event per decided meeting): `docs/exec-plans/process-log.jsonl`

## Working on iOS code (Claude Code domain)

- App source: `workspace/ios/` (do not open until a round whitelist permits)
- Project spec: `workspace/ios/project.yml`
- Theme tokens: `workspace/ios/.../UnfadingTheme.swift` (find via grep inside round)
- Coding conventions: `docs/references/coding-conventions.md`
- iOS architecture: `docs/design-docs/ios-architecture.md`
- Skills (before any task): `SKILLS.md`
- Security policy: `SECURITY.md`

## Working on product/design (Codex domain)

- Design-revision workflow: `docs/design-docs/design-revision-workflow.md`
- Deepsight prototype (first v5 round input): `docs/design-docs/travel_deepsight/` (HTML + screenshots)
- HF round acceptance: `docs/product-specs/hf-round1-acceptance.md`, `docs/product-specs/hf-round2-acceptance.md`
- UI/UX screen contract: `context_harness/prd/ui_ux_screen_contract.md`
- Supabase schema: `docs/references/supabase-schema.md`
- Legacy multi-agent architecture: `docs/design-docs/multi-agent-architecture.md` (SUPERSEDED — kept for history)
- Vibe-coding limits + harness regulation (v5.7): `docs/design-docs/vibe-coding-limits-2026.md`
- Monetization strategy (v5.7): `docs/product-specs/unfading-monetization-strategy.md`

## Tracking what happened

- Sprint history: `docs/exec-plans/sprint-history.md`
- Process log (JSONL): `docs/exec-plans/process-log.jsonl`
- Metrics (JSONL): `docs/exec-plans/metrics.jsonl` (create if missing)
- Blackboard (last 5 entries append-only): `context_harness/blackboard.md`
- Handoff ledger: `context_harness/handoff_ledger.jsonl`
- Operator journal: `context_harness/operator_journal.md`

## Historical sprint briefs (Layer 3, do not bulk-read)

- All sprint briefs: `context_harness/handoffs/sprint<N>_*.md`
- All remediation briefs: `context_harness/handoffs/remediation_*.md`
- HF human feedback: `context_harness/handoffs/human_feedback_r1.md`, `human_feedback_r2.md`
- Rule: open a specific brief only when referenced by round contract or meeting

## Evaluation artifacts

- Raw evaluation reports: `context_harness/reports/*.md` (red_team, hig_guardian, visual_qa, xcode_runtime, etc.)
- Screenshots (Round 0 and earlier): `context_harness/reports/screenshots/`
- Future per-round evidence: `context_harness/reports/<round_id>/` (created per round)

## Harness infrastructure code

- Entry point orchestrator: `orchestrator.py`
- Master router: `master_router.py`
- Providers: `harness/providers.py`
- Ops modules: `harness/ops/probes.py`, `harness/ops/roles.py`
- Context manager: `harness/context_manager.py`
- Guardrails: `harness/guardrails.py`
- Runtime QA: `harness/runtime_qa.py`
- Eval calibration: `harness/eval_calibration.py`
- Round checker (v5 addition): `harness/check_operator_round.py`

## Team manifest and provider configuration

- Team manifest: `context_harness/team_manifest.json`
- System rules (legacy): `context_harness/00_system_rules.md`
- State: `context_harness/state.json`

## Memory (user-persistent, auto-memory)

- Index: `/Users/jeonsihyeon/.claude/projects/-Users-jeonsihyeon-factory/memory/MEMORY.md`
- Individual entries: files next to MEMORY.md, one per topic
- Rule: verify freshness before citing; see `OPERATOR.md §Core Principles`

## Git

- Working tree: `/Users/jeonsihyeon/factory`
- Integration worktree: `/Users/jeonsihyeon/factory/.worktrees/_integration`
- Branch: `master`

## Images and binaries

- Design references: `docs/design-docs/travel_deepsight/*.png`, `*.html`
- Runtime screenshots: `context_harness/reports/**/*.png` and `context_harness/reports/screenshots/`

## Secrets

- Never read or commit: `.mcp.json`, `.env`, any `*.key`, `*.pem`
- Supabase token reference: `~/.claude/projects/-Users-jeonsihyeon-factory/memory/reference_supabase.md`
- Security policy: `SECURITY.md`

## What NOT to open without reason

- `__pycache__/`, `archived_workspaces/`, `.worktrees/`, `.codex/`, `.claude/` (beyond `CLAUDE.md`)
- Any `_archive/` subdirectory
- Legacy bird/cifar research artifacts (already removed from tree)

---

**When this file grows past 250 lines:** split into:
- `indexes/ios_code.md`
- `indexes/harness_infra.md`
- `indexes/historical.md`

And keep FILE_INDEX.md as a two-level table of contents pointing to them.
