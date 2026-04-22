---
round: none
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260422-v5-bootstrap-drift-fix
contract_hash: none
created_at: 2026-04-22T18:00:00Z
---

# Meeting — v5 Bootstrap Drift Fix

**Trigger:** Stop-hook review gate flagged "v5 bootstrap has governance drift that would make the new gate process unreliable" after commit `7f9789a`. Exactly the cross-validation regime v5 exists to provide.

**Chair:** Claude Code Operator
**Peer:** Codex Operator (gpt-5.4, session `019db43d-746e-73b3-b33c-5dda3770df91`, continued from kickoff)
**Scope:** Corrective amendment; no reopening of v5 normative decisions.

## Context

- v5 bootstrap committed 2026-04-19 at `7f9789a`. Checker reported 14 passes / 0 blockers.
- Stop-hook review (Codex) flagged governance drift. Checker's green status was overclaiming coverage.
- Detailed review captured at `/tmp/codex_drift_detail.log`. 12 blockers + 3 advisories identified.
- All items are routine (implementation-vs-decision drift), not normative.

## Findings from Codex Review

### Blockers (12) — round cannot advance; fix before any new round starts

1. **YAML/TOML path drift** — REGULATION, FILE_INDEX, STAGE_CONTRACT, CHANGELOG, checker docstring all cite `operator/lint_config.yaml`; actual committed file is `lint_config.toml`.
2. **FILE_INDEX coverage scan too narrow** — `required_scan_globs` only `*.md`; misses `lint_config.toml`. Coverage check passes while ignoring a governance file.
3. **Whitelist-shrink exception contradicts immutability** (REGULATION §3) — "shrinking allowed without meeting" mutates lock hash by definition.
4. **Amendment schema only covers `spec.amendment.N.md`** — no artifact format for whitelist/acceptance/eval_protocol amendments. First zone-crossing will invent incompatible formats.
5. **Lint/convention hash not actually verified** — `lint_config.txt` and `convention_version.txt` are hashed in lock, but checker never compares their content's SHA to live `lint_config.toml` / `coding-conventions.md`. Lint can drift mid-round invisibly.
6. **Operator-layer drift audit mostly unimplemented** — REG §7 promises 8 checks; checker executes ~2. 7/7 passes overclaim coverage. Real risk: drift exists but goes undetected.
7. **Stage name inconsistency** — STAGE_CONTRACT uses display names ("Overall Planning"); MEETING_PROTOCOL and lint config require snake IDs (`overall_planning`). Stage matching across docs broken.
8. **Evaluation artifact path drift** — Loaders + STAGE_CONTRACT say `reports/<round>/...`; FILE_INDEX + Q4 decision say `context_harness/reports/<round_id>/...`. Evidence may be written outside indexed tree.
9. **OPERATOR.md "verify checker output says `ready`"** — checker never emits that token. Stage-start rule depends on a nonexistent success marker.
10. **Close authority contradiction** — docs say checker transitions lock to `closed`; checker only reads. PROCESS_AUDIT line 21 also requires lock "not active" before close, which is backwards.
11. **Commit traceability blocker declared but not enforced** — `gates` doesn't inspect commits or whitelist compliance. Round can close with out-of-whitelist edits under zero-blocker status.
12. **Factual meeting evidence refs declared but not checked** — checker only validates the phrase "No normative decision; verified facts only"; no Evidence section or path/hash verification.

### Advisories (3)

1. **SESSION_RESUME stale** — file dated 2026-04-19, today 2026-04-22 (3 days).
2. **Missing process-log JSONL event** for `20260419-v5-bootstrap` decision.
3. **FILE_INDEX warn threshold = cap** (both 250) — zero advisory window. Recommended: warn 225 / cap 250.

## Decision

**ACCEPTED ALL 15 items verbatim** as routine corrective amendments. No v5 decision reopened.

Fix plan (applied in the same commit as this meeting):

### Doc fixes
- REGULATION.md: yaml→toml (item 1), drop whitelist shrink exception (item 3), add generic amendment artifact schema (item 4), clarify lint hash = live file SHA (item 5), clarify close authority = checker `close` subcommand (item 10)
- STAGE_CONTRACT.md: add `stage_id` column matching lint config (item 7), normalize artifact paths to `context_harness/reports/<round_id>/...` (item 8)
- OPERATOR.md: replace "verify `ready`" with "exit code 0 and no blockers" (item 9)
- PROCESS_AUDIT_CHECKLIST.md: fix backwards "not active" rule (item 10)
- FILE_INDEX.md: yaml→toml (item 1), add `lint_config.toml` entry (item 2)
- CHANGELOG.md: yaml→toml (item 1), append drift-fix entry
- .claude/CLAUDE.md, AGENTS.md: normalize report path (item 8)
- lint_config.toml: include non-md glob scan (item 2), warn threshold 225 (advisory 3)

### Checker implementation
- Docstring: yaml→toml (item 1)
- FILE_INDEX coverage: scan all operator/* with exemptions (item 2)
- audit-operator-layer: implement stage ID parsing + cross-doc comparison, SESSION_RESUME freshness, legacy SUPERSEDED header check, file existence extraction, lock stages_completed performer/cross-validator validation (items 6, 7)
- Factual meeting validator: require Evidence section with ≥1 path/command reference (item 12)
- Lint/convention hash: compute actual live file SHA and compare to locked (item 5)
- `close <round>` subcommand: run gates → if pass, transition lock `status: closed` + set `closed_at` (item 10)
- `gates`: commit traceability (git log since lock `started_at`, touched files vs effective whitelist) (item 11)
- Amendment schema: lock `amendments[]` accepts `target` field covering any base contract file (item 4)

### Log repairs
- SESSION_RESUME.md: update v5 section with drift-fix outcome and today's date (advisory 1)
- process-log.jsonl: append `meeting_decided` events for `20260419-v5-bootstrap` and `20260422-v5-bootstrap-drift-fix` (advisory 2)

### Codex peer review of this fix
Codex pre-agreed these are routine amendments; re-review of the applied fixes happens via stop-hook review on the next commit. If stop-hook re-flags anything, open a new drift meeting — don't retry silently.

## Challenge Section

### Objection (recorded, by Claude Code Operator)
Codex's item 3 (drop whitelist shrink exception) was initially motivated in my draft by an anti-drift intent — if you realized a file shouldn't be writable, shrinking seemed safer than keeping it. But Codex is correct: ANY change to a locked base file mutates its hash. "Shrink without meeting" teaches operators to bypass immutability. Accepted.

### Risk
Checker implementation items 5, 6, 10, 11, 12 are substantive code additions. Risk: new bugs in the checker itself. Mitigation: each new check tested against the current repo state. If checker breaks, commit is held until fixes pass.

### Rejected alternative
Splitting this fix into multiple commits (doc-only → checker impl → log). Rejected because the stop-hook gate is blocking session close and Gate 5 blockers must be fully resolved before round work can resume. Single atomic fix commit is more defensible for the audit trail.

### Uncertainty deferred
Commit traceability (item 11) needs a `base_commit` field in the lock and a convention for what "round commits" means before the first real round exists. Deferred to first real round's lock creation; placeholder implementation in checker now warns if `base_commit` is absent.

## Decision
PROCEED with all 15 fixes in a single commit. This meeting file + CHANGELOG v5.1 entry document the change. Re-run checker after fixes; must show 0 blockers. Commit + push only after 0 blockers confirmed.
