# Operator CHANGELOG

Append-only. Every operator-doc amendment must add an entry with date, summary, and meeting pointer.

---

## v5.2 — Second Drift Fix (2026-04-22)

**Meeting:** [`meetings/2026-04-22_v5.2_drift_fix.md`](meetings/2026-04-22_v5.2_drift_fix.md)
**Decision ID:** `20260422-v5.2-drift-fix`
**Trigger:** Stop-hook review (Codex) after `d0e73bc` flagged "d0e73bc still leaves governance drift in the checker/docs". Second drift-fix iteration. 7 blockers + 3 advisories identified, all routine. Trend: converging (v5.0: 12+3 → v5.1: 7+3 → v5.2: hopefully 0+0).

### Fixed (7 blockers)

1. **Version header drift** — bumped REGULATION, STAGE_CONTRACT, OPERATOR, PROCESS_AUDIT_CHECKLIST, MEETING_PROTOCOL to `v5.2`. REG §11 version bump honored.
2. **Amendment schema now validated** — new `validate_amendments()` in checker verifies: file exists + SHA matches lock + frontmatter has `target`/`supersedes`/`meeting` + meeting exists with `status: decided` + target is a base contract file. REGULATION's "effective regeneration" claim narrowed to "consumers compute on read".
3. **`close` requires external gate evidence** — checker `cmd_close` now reads `contracts/<round>/gate_evidence.json` and refuses close if `gate1..gate4` are not all `status: pass`. REGULATION wording narrowed to "Gate 5 + gate_evidence for Gates 1-4".
4. **Commit traceability** — (a) includes uncommitted + staged via `git status --porcelain`; (b) glob matcher replaced with regex-based POSIX semantics (`*` = `[^/]*`, `**` = `.*`, with `/**` / `**/` normalization); (c) `workspace/ios/**/*.swift` now supported. 13/14 smoke tests pass.
5. **Malformed pointer file = blocker** (was advisory). Bad `lint_config.txt` / `convention_version.txt` format no longer silently bypasses live hash check.
6. **REG §7 honesty update** — operator-layer drift audit section rewritten to list ONLY what the checker enforces (9 checks). Explicitly marks role matrix full consistency, process-log event counts, and effective amendment regeneration as NOT enforced in v5.2.
7. **Missing referenced paths = blocker** (was advisory) with explicit allowlist from `lint_config.toml [path_existence].allowlist_placeholders`. Allowlisted paths still produce advisory (e.g., `operator/indexes/` future directory).

### Fixed (3 advisories)

1. **PROCESS_AUDIT warn band aligned** with lint config (225 warn, 250 cap).
2. **CHANGELOG v5.0 historical note** added — original YAML reference preserved verbatim with v5.2 annotation explaining migration.
3. **Pointer file format example** added to REGULATION §3 (`<path>\n<sha256>`).

### Checker added in v5.2

- `validate_amendments(lock)` — base contract amendment validation
- `validate_stages_completed(lock, cfg)` — structural stage_id validation
- `load_gate_evidence(round_id)` — external gate_evidence.json reader
- `_match_glob(rel, pattern)` — strict POSIX-semantics glob matcher replacing fragile prefix logic
- `check_commit_traceability` now also uses `git status --porcelain`

### Narrowed REGULATION claims (honesty over aspiration)

- Dropped "effective file regeneration" from amendment artifact description
- Narrowed `close` to "Gate 5 + gate_evidence.json"
- Narrowed REG §7 to enforced checks list; deferred full role-matrix validation to a future peer-review amendment if needed

### Classification
All 10 items routine corrective amendments. No v5 principle reopened. Convergence expected — same stop-hook should no longer flag these specific patterns.

---

## v5.1 — Bootstrap Drift Fix (2026-04-22)

**Meeting:** [`meetings/2026-04-22_v5_bootstrap_drift.md`](meetings/2026-04-22_v5_bootstrap_drift.md)
**Decision ID:** `20260422-v5-bootstrap-drift-fix`
**Trigger:** Stop-hook review (Codex) after `7f9789a` flagged "v5 bootstrap has governance drift that would make the new gate process unreliable". Exactly the cross-validation regime v5 exists to provide.

### Fixed (12 blockers)

1. **YAML/TOML path drift** — normalized all references to `operator/lint_config.toml` across REGULATION, STAGE_CONTRACT, FILE_INDEX, CHANGELOG, checker docstring.
2. **FILE_INDEX coverage scope** — extended scan globs to include `*.toml`, `*.yaml`, `*.yml`; added explicit `lint_config.toml` pointer in FILE_INDEX.
3. **Contract immutability contradiction** — removed the "whitelist shrinking allowed without meeting" exception. All whitelist changes (expand or shrink) now require amendment meeting.
4. **Generic amendment schema** — REGULATION §3 now defines `<base>.amendment.<N>.<ext>` pattern with `target`/`supersedes`/`meeting` frontmatter, applicable to whitelist/acceptance/eval_protocol/spec.
5. **Live lint/convention hash enforcement** — `lint_config.txt` and `convention_version.txt` now hold `<path>\n<sha>`; checker recomputes live SHA at Gate 5 and fails on mismatch.
6. **Operator-layer drift audit** — checker now implements: stage ID consistency across STAGE_CONTRACT/MEETING_PROTOCOL/lint_config, SESSION_RESUME freshness (>48h advisory, >7d blocker), legacy SUPERSEDED/ACTIVE header validation, referenced-path existence check (handles `operator/` shorthand).
7. **Stage ID vs display name split** — STAGE_CONTRACT adds canonical `stage_id` column matching lint config snake_case values; display names kept as labels only.
8. **Evaluation artifact paths** — normalized to `context_harness/reports/<round_id>/evidence|verdict|gate2/` across all operator docs.
9. **OPERATOR `ready` pseudo-token** — replaced with "exit code 0 and no blockers" rule.
10. **Close authority clarified** — new `close <round>` checker subcommand transitions lock `status: closed` + `closed_at` only after gates pass; operators may not hand-edit status. PROCESS_AUDIT line 21 rule corrected ("lock status is active before close" — not "not active").
11. **Commit traceability implemented** — lock now records `base_commit`; `gates` runs `git diff --name-only` since base and verifies all changed paths match effective whitelist (base + amendments).
12. **Factual meeting evidence refs enforced** — checker requires `Evidence:` section with ≥1 bullet containing a path or command reference (not only the factual phrase).

### Fixed (3 advisories)

1. **SESSION_RESUME freshness** — v5 section updated with drift-fix outcome, current date.
2. **Process log events** — retroactive `meeting_decided` JSONL events appended for bootstrap (`20260419-v5-bootstrap`) and drift-fix (`20260422-v5-bootstrap-drift-fix`) meetings.
3. **FILE_INDEX warn threshold** — lowered from 250 (= cap) to 225 for a useful advisory window.

### Checker upgrade

- New subcommand: `close <round_id>` — atomic gate pass + status transition.
- New Gate 5 checks: commit traceability, live pointer hashes, SESSION_RESUME freshness, legacy header markers, stage ID cross-doc consistency, factual meeting evidence refs.
- Path resolver handles `operator/<file>` shorthand inside operator docs.

### No normative changes
All 15 items are corrective implementation drift from already-locked v5 decisions. No peer review needed per Codex's classification.

---

## v5.0 — Bootstrap (2026-04-19)

> **Historical note (added in v5.2):** The original v5.0 entry below referenced `operator/lint_config.yaml`. During v5.1 bootstrap the config was migrated to TOML; this historical entry is preserved verbatim for audit trail. Active governance references all use `lint_config.toml` as of v5.1.


**Meeting:** [`meetings/2026-04-19_v5_kickoff.md`](meetings/2026-04-19_v5_kickoff.md)
**Decision ID:** `20260419-v5-bootstrap`
**Participants:** Claude Code Operator, Codex Operator (gpt-5.4, session `019db43d-746e-73b3-b33c-5dda3770df91`)

### Added
- `operator/OPERATOR.md` — shared persona + decision principles (≤120 lines)
- `operator/REGULATION.md` — precedence ladder, lock schema, immutability, Challenge Section, Gate 5 split, deadlock escalation ladder, operator-layer drift audit, linter enforcement, SKILLS update protocol
- `operator/STAGE_CONTRACT.md` — 13-stage matrix with Performer/Cross-Validator/Pattern, parallel-vs-serial rules, ownership zones, evidence-vs-verdict rule
- `operator/MEETING_PROTOCOL.md` — meeting file template, frontmatter schema, Challenge Section rule, Codex CLI session lifecycle
- `operator/FILE_INDEX.md` — use-case → file pointer index (≤250 lines)
- `operator/PROCESS_AUDIT_CHECKLIST.md` — Gate 5 blockers/advisories + retro mandatory content
- `operator/proposals/v5_overhaul_proposal.md` — original proposal (draft that was reviewed)
- `operator/meetings/2026-04-19_v5_kickoff.md` — 3-round peer review meeting
- `operator/lint_config.yaml` — operator-doc lint rules (Round 0 scope: operator docs only)
- `harness/check_operator_round.py` — lock / gates / audit-operator-layer checker

### Changed
- `.claude/CLAUDE.md` — shrunk to ≤80-line thin loader pointing to `operator/`
- `docs/design-docs/multi-agent-architecture.md` — marked SUPERSEDED (v4); header now points to v5 operator docs
- `context_harness/SESSION_RESUME.md` — added v5 bootstrap section

### New file (previously missing)
- `AGENTS.md` (repo root) — Codex Operator thin loader pointing to `operator/`

### Governance additions locked by this release
- Two equal co-operators (no principal/secondary)
- 14 decisions locked in the 2026-04-19 kickoff meeting
- Precedence ladder: active round contract+lock > REGULATION > STAGE_CONTRACT > OPERATOR > domain workflows > legacy docs
- Deadlock ladder: reframe → default-reversible → Gemini advisory (technical only) → human escalation
- Challenge Section mandatory on decision meetings; factual meetings state "No normative decision; verified facts only" + evidence refs
- Gate 5 blockers: lock mapping, contract immutability, unreviewed meetings, FILE_INDEX coverage, lint hash, operator-layer drift, escalation status
- Gate 5 advisories: SKILLS update conditional on novel pattern, SESSION_RESUME freshness
- Real-use evaluation split: rubric (Codex) / capture (Claude Code, evidence-only) / verdict (Codex)
- Contract immutability: base files never edited; amendments as `spec.amendment.N.md` + `supersedes` field in lock

### Residual uncertainty (to resolve in first real round)
- Exact lock JSON schema subject to Codex review at first round creation
- Round 0 linter scope = operator docs only; Swift linter deferred to later retro
- SESSION_RESUME.md governance: live snapshot, not meeting-gated; contradictions caught by drift audit

### Deferred to next rounds
- Deepsight redesign processing (will be Round 1 under v5, sliced per `design-revision-workflow.md` Phase 3)
- Round retro template instantiation (first use at Round 1 close)
- Gemini advisory invocation mechanics (document when first triggered)
