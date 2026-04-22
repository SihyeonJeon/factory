# Operator CHANGELOG

Append-only. Every operator-doc amendment must add an entry with date, summary, and meeting pointer.

---

## v5.7 — Swift Impl Delegation + Vibe-Coding Regulation + Monetization (2026-04-23)

**Meeting:** [`meetings/2026-04-23_swift_impl_delegation_and_vibe_limits.md`](meetings/2026-04-23_swift_impl_delegation_and_vibe_limits.md)
**Decision ID:** `20260423-swift-impl-delegation-vibe-limits`
**Trigger:** User 8-hour autonomous directive requiring operator-doesn't-edit-code discipline + launch-ready app + beta-unnecessary quality.

### REGULATION changes
- §2 narrowed Claude Code Operator: no direct Swift edits; all impl dispatched to Codex
- §2 widened Codex Operator: owns `workspace/ios/**/*.swift`
- §5.1 new blocker: "operator modified Swift file directly" (forward-looking from R5)
- §12 (new): Multi-axis Evaluation — 5 axes (code / runtime functional / UI-UX fidelity / nav+info consistency / process-context)
- §13 (new): Vibe-Coding Regulation — every dispatch cites vibe-coding-limits-2026 items; returned Swift must include `// vibe-limit-checked:` comment; fresh review session

### STAGE_CONTRACT changes
- Stage 7 `coding_1st` performer: Claude Code → Codex (dispatched session)
- Stage 11 `coding_2nd` performer: Claude Code implements → Codex dispatched session implements
- Ownership zones: `workspace/ios/**/*.swift` moved from Claude Code to Codex

### New documents
- `docs/design-docs/vibe-coding-limits-2026.md` — 15 anti-patterns + harness counter-regulations (Codex-authored)
- `docs/product-specs/unfading-monetization-strategy.md` — freemium + premium tiers, KRW pricing, Korean market, retention, StoreKit 2 checklist (Codex-authored)

### FILE_INDEX
- Added pointers to vibe-coding-limits-2026.md + unfading-monetization-strategy.md

### Enforcement note
v5.7 is forward-looking from R5. Past rounds (R2-R4) had operator-authored Swift edits as historical debt; grandfathered. R5+ must dispatch all Swift to Codex.

### Deleted (cleaned up)
- `context_harness/operator/REGULATION.amendment.swift-impl-delegation.md` (was a draft holder; actual amendment applied inline to REGULATION.md + STAGE_CONTRACT.md per §11 protocol for operator-doc amendments)

---

## v5.6 — CHANGELOG Meeting-Trail Enforcement (2026-04-22)

**Meeting:** [`meetings/2026-04-22_v5.6_meeting_trail.md`](meetings/2026-04-22_v5.6_meeting_trail.md) — explicit file authored to avoid self-exemption
**Decision ID:** `20260422-v5.6-meeting-trail`
**Trigger:** Stop-hook iteration 6 flagged "v5.5 core operator-doc edits lack the required meeting/process-log trail". Legitimate — REGULATION §11 required meetings for v5.4 and v5.5; I skipped them treating those as "code implementation". Confirmed gap.

### Retroactive fixes

- Authored `meetings/2026-04-22_v5.4_amend_impl.md` (retroactive, decision_id `20260422-v5.4-amend-impl`) with full Challenge Section including honest objection about why I skipped
- Authored `meetings/2026-04-22_v5.5_amend_safety.md` (retroactive, decision_id `20260422-v5.5-amend-safety`) with Challenge Section including objection about the "empirically verified" v5.4 claim that only covered `.md` paths
- Appended 2 `meeting_decided` JSONL events to `docs/exec-plans/process-log.jsonl`
- Linked both meetings from their respective CHANGELOG entries

### Enforcement added (prevents recurrence)

- `check_operator_round.py audit_operator_layer`: parse CHANGELOG.md for every `## v5.X` entry; extract the meeting pointer from the `**Meeting:**` line; verify the referenced meeting file exists. Missing meeting file → Gate 5 blocker.
- Exception: if CHANGELOG entry explicitly states `this-entry (meta-amendment...)` — meta entries that describe themselves don't need a separate meeting file. Regex pattern: `this-entry`.

### Scope limit

The audit only checks file existence, not content correctness. A malicious operator could still create an empty shell meeting file. Per v5.3 trust model (honest-agent, not malicious-fabrication resistant), this is acceptable — the point is to make the gap obvious, not to prevent determined bad actors.

### Empirical verification

After adding this audit: `audit-operator-layer` on current state shows all CHANGELOG entries have valid meeting pointers (v5.0 kickoff, v5.1 bootstrap_drift, v5.2 drift_fix, v5.3 bypass_fix, v5.4 amend_impl retroactive, v5.5 amend_safety retroactive). 0 blockers.

### Why iteration 6 is the right stopping condition (for this harness track)

Each iteration has closed a narrower class of issue:
- v5.1: doc drift (documentation-code consistency)
- v5.2: impl-vs-doc drift (same axis, narrower)
- v5.3: exploit enumeration (different axis: what can an operator silently do)
- v5.4: flow holes (yet another axis: what commands are missing)
- v5.5: flow implementation bugs (narrower: bugs IN the newly-added amend flow)
- v5.6: process compliance (narrowest: did I follow my own procedure?)

v5.6 closes the process-compliance gap that let v5.4 and v5.5 ship without meetings. The next stop-hook iteration — if one fires — should hit a qualitatively new axis. If it hits the same axis (missing meetings, missing tests, missing enforcement), the harness has a deeper flaw worth pausing the loop to reconsider.

---

## v5.5 — Amend Flow Safety Fixes (2026-04-22)

**Meeting:** [`meetings/2026-04-22_v5.5_amend_safety.md`](meetings/2026-04-22_v5.5_amend_safety.md) (retroactively authored on iteration 6 to close REG §11 compliance gap)
**Decision ID:** `20260422-v5.5-amend-safety`
**Trigger:** Stop-hook after `cfd9890` flagged "new amend flow cannot safely ship". Codex R7 critique enumerated 5 REAL issues + 3 theoretical. All REAL issues addressed; theoretical deferred per trust-model scope.

**Evidence of empirical gap in v5.4:** my v5.4 smoke test only exercised `.md` amendments (happy path + invalid target). `.txt` amendment path was never exercised — and it turns out v5.4 `.txt` amendments ALWAYS rolled back because `supersedes=[]` failed `validate_amendments`'s missing-metadata check. Classic untested-path regression.

### Fixed (5 REAL)

1. **`.txt` amendment default `supersedes=[target]`** — was empty list, which `validate_amendments` treated as missing metadata and rejected. Made `.txt` amendments functionally broken. Empirically verified fixed on `test_amend_r2` (new smoke).

2. **Path containment on `amendment_file` argument** — previously could accept `../other_round/foo`. Now enforces `Path(amendment_file).name == amendment_file` (basename-only) AND post-join resolve check (`ap.resolve().parent == round_dir.resolve()`). Empirically verified: `../round_deepsight_r1/spec.md` rejected with "must be a basename".

3. **Meeting path canonicalization** — v5.4 compared raw strings, so `context_harness/operator/meetings/foo.md` in frontmatter vs `foo.md` as CLI arg rejected even though they resolved to the same file. v5.5 canonicalizes both to `context_harness/operator/meetings/<name>.md` and compares/stores canonical form. Empirically verified: bare filename CLI arg now resolves correctly.

4. **Pre-write validation** — v5.4 wrote lock then validated then rolled back on failure (disk flicker, stranded-lock risk on crash). v5.5 simulates the new lock in memory, runs `validate_amendments` before any disk write. Lock only written on validation success. Also added exception handling on `_append_lock_event` with rollback. Empirically verified: invalid meeting caught pre-write with message "amend refused; lock unchanged" (no rollback message).

5. **Closed-round deliverable revalidation** — v5.4's `commit_traceability` skip for closed rounds left round deliverables (gate_evidence.json's embedded path+sha references) mutable without detection. v5.5: after verifying `gate_evidence.json` sha itself matches lock, ALSO re-runs `load_gate_evidence()` to verify all embedded path+sha references. Any deliverable mutation post-close → blocker. Empirically verified on `round_deepsight_r1`: appended a line to `deepsight_tokens.md` → blocker `gate_evidence.gate2.reports[0] sha mismatch`.

### Deferred (3 THEORETICAL, fault-only)

1. Crash between lock write and event append (fault-only; longer-term: temp files + fsync)
2. Event append disk-full/permission error (narrow catch added in v5.5; full solution same as #1)
3. Greedy `.txt` regex (already rejected by `REQUIRED_CONTRACT_FILES` check; v5.5 tightened regex to `[A-Za-z0-9_]+` for base)

### Lesson recorded from round_deepsight_r1 retrospective

**Do NOT point `gate_evidence` at live-snapshot files.** Round 1 used `SESSION_RESUME.md` as `gate1.log` (baseline reuse for contract-only round) and `process-log.jsonl` as `gate4.metrics_source`. Both files are legitimately mutable outside any specific round. After close, every subsequent update to them trips the v5.5 deliverable revalidation check when `gates round_deepsight_r1` runs. Operational workaround: accept the drift as an audit trail showing "round 1 was closed at this point in time; live snapshots have moved on." For round 2+: use immutable logs (e.g., a dedicated `xcode_test_round2.log` copy) for `gate1.log`, and consider freezing a metrics snapshot at close.

### Empirical test summary

- `test_amend_r2` smoke:
  - `.txt` amendment (`file_whitelist.amendment.1.txt`) registered + `amended` event with post-sha ✓
  - path escape (`../round_deepsight_r1/spec.md`) rejected ✓
  - bare filename meeting (`2026-04-22_test_amend_r2_txt.md`) canonical match proceeds to content validation ✓
  - invalid name (`notabase.amendment.1.txt`) rejected by stricter regex ✓
- `round_deepsight_r1` post-close deliverable tamper:
  - append line to `deepsight_tokens.md` → `gate_evidence.gate2.reports[0] sha mismatch` ✓
  - restore → integrity verified ✓

Test artifacts cleaned up after verification.

Checker post-v5.5 state:
- lint: 7 passes / 0 blockers
- audit-operator-layer: 10 passes / 1 advisory (allowlisted future path)
- `gates round_deepsight_r1`: depends on whether SESSION_RESUME/process-log have moved since round close; blockers are accepted drift, not bugs

---

## v5.4 — Real-Use P0 Fixes (2026-04-22)

**Meeting:** [`meetings/2026-04-22_v5.4_amend_impl.md`](meetings/2026-04-22_v5.4_amend_impl.md) (retroactively authored on iteration 6 to close REG §11 compliance gap)
**Decision ID:** `20260422-v5.4-amend-impl`
**Evidence:** `context_harness/reports/round_deepsight_r1/evidence/checker_friction.md`
**Codex confirmation:** R7 (`context_harness/operator/codex_transcripts/codex_v5_4_confirm.log`) — 3 adjustments + 1 additional check accepted.
**Trigger:** round_deepsight_r1 empirically confirmed Codex R5 blockers #1 (no `amend` command) and #4 (post-close evidence not revalidated) as REAL.

### Added (2 narrow fixes)

1. **`amend <round_id> <amendment_file> <meeting_path>` subcommand** — evented amendment flow that was missing in v5.3. Pre-checks lock status + tamper evidence, validates amendment metadata, writes lock atomically, appends `amended` event with post-amend lock sha. Rolls back to pre-amend lock text if post-write validation fails (no `amended` event emitted in rollback).
   - `.md` amendments: parse frontmatter, cross-check `meeting` field against CLI arg.
   - `.txt` amendments: infer `target` from filename (`<base>.amendment.N.txt` → `<base>.txt`); target must be in `REQUIRED_CONTRACT_FILES`.
   - Rejects duplicates, close-state corruption (`gate_evidence_sha256` set or `closed_at` non-null), or any pre-check failure.
   - Closes Codex blocker #1. Empirically verified end-to-end on `test_amend_r1` smoke round (happy path + invalid-target rejection).

2. **Post-close gate evidence revalidation in `cmd_gates`** — when `lock.status == "closed"` and `lock.gate_evidence_sha256` is set, the checker recomputes live `gate_evidence.json` sha and blocks on mismatch. Closes Codex blocker #4. Empirically verified: tampered `gate_evidence.json` with fabricated content post-close → `gates` blocker fires; restore → passes.

### Not in v5.4 scope (deferred from Codex R5)

- #2 atomic lock+event (no crash experienced)
- #3 event sequence validation (only `created`→`amended`→`closed` emitted by commands; manual event injection beyond scope)
- #5 schema_version enforcement (no v1 locks in use)
- #6 manual close provenance (orthogonal to v5.4 fixes)
- #7 amendment meeting must require both participants (routine but batched for later)
- #10 paused/escalated/aborted evented commands (no deadlock observed)

### Other changes

- REGULATION §3: amendment flow described as evented; post-close revalidation section added
- STAGE_CONTRACT/OPERATOR/MEETING_PROTOCOL/PROCESS_AUDIT_CHECKLIST: version bumped to v5.4
- FILE_INDEX: `amend` listed in checker commands
- Docstring of `harness/check_operator_round.py` updated

### Empirical test evidence

`test_amend_r1` smoke round (cleaned up after verification):
- `lock` → 9 passes / 0 blockers, `created` event logged
- `amend ... spec.amendment.1.md ...` → 3 passes / 0 blockers, amendment registered with valid target/meeting/sha, `amended` event logged with post-amend lock sha
- `amend ... spec.amendment.2.md ...` (invalid target `nonexistent.md`) → 1 blocker rejected pre-write, lock amendments count unchanged (rollback verified)
- `gates` → 1 valid amendment accepted; unregistered `spec.amendment.2.md` on disk correctly flagged as blocker per v5.3 disk-scan rule

`round_deepsight_r1` post-close tamper test:
- Replaced `gate_evidence.json` with `{"TAMPERED_FOR_TEST":true}` → `gates` blocker: `gate_evidence.json tampered after close: locked=sha256:46945f05... live=sha256:cfbf46c1...`
- Restored → `ok gate_evidence.json post-close integrity verified`

Checker state after v5.4 on round_deepsight_r1 (closed): **0 blockers / 1 advisory (allowlisted future path) / 27 passes.**

---

## v5.3 — Governance Bypass Fix (2026-04-22)

**Meeting:** [`meetings/2026-04-22_v5.3_bypass_fix.md`](meetings/2026-04-22_v5.3_bypass_fix.md)
**Decision ID:** `20260422-v5.3-bypass-fix`
**Trigger:** Stop-hook review after `d1cf6b4` flagged "v5.2 amendment validation still leaves governance bypasses". Third iteration. Codex moved from drift to enumerating **11 specific exploits** + 3 residual drift items, recommended **block**.

### Trust model (new, ratified in this meeting)

v5 is an **honest-agent error-reduction regime with tamper-evident audit trail**. NOT malicious-fabrication resistant. Rationale: operators are OAuth-authenticated sessions; true adversarial resistance needs external trust anchor. Deferred explicitly: cryptographic identity proof, external trusted logs, human-approval gate on close.

### Tamper-evident primitives (new)

- **Per-round lock event log**: `operator/locks/<round_id>.events.jsonl`. Append-only `{ts, action, lock_sha256, base_commit, amendment_file}` on `created`/`amended`/`closed`. Checker recomputes current lock sha and blocks if it differs from the last event. `close` is the only action that advances sha; records post-close sha (Codex R4 Q6 fix).
- **Gate evidence hashed into lock at close** — new field `lock.gate_evidence_sha256`. Later edits detectable.
- **Codex identity presence** — meeting frontmatter `codex_session_id` (regex `[A-Za-z0-9._:-]{8,}`) and/or `codex_transcript` (file path must exist). Required when `codex` is in participants. Transcripts persisted at `context_harness/operator/codex_transcripts/`.

### Amendment bypass closure (blockers 1-4, 9 of Codex enumeration)

- Checker disk-scans `*.amendment.*` files; unregistered file = blocker
- Every amendment requires: `file`, `target`, `sha256` (starts with `sha256:`), `supersedes`, `meeting` in lock
- `.md` amendments: frontmatter `target`/`meeting` must match lock entry
- `.txt` amendments: body format (`+path`/`-path` lines) validated
- Meeting must be `status: decided`, `round` matching lock, stage amendment-eligible, and body contains `## Amendment Detail` referencing amendment filename

### Gate evidence strict schema (blocker 7-8)

`gate_evidence.json` per-gate required fields:
- `gate1`: status, command, exit_code, test_count, log (path+sha256)
- `gate2`: status, reports (array of 3 path+sha)
- `gate3`: status, cross_agreement_note OR summary (path+sha)
- `gate4`: status, metrics_source (path+sha), remediation_cycles, blocker_recurrence

Checker verifies all referenced paths exist and SHAs match.

### Other fixes

- **`cmd_lock` refuses pre-existing amendment files** (blocker surface for silent rebinding)
- **`stages_completed` demoted to informational** — ID membership only, never gates
- **Residual doc drift**: REGULATION `.effective.*` claim removed; PROCESS_AUDIT role matrix line aligned with v5.2 NOT-enforced list; CHANGELOG v5.2 13/14 note retained with explicit known edge case

### Lock schema bump

Schema version `1` → `2`. New fields: `gate_evidence_sha256`. Field `stages_completed` now informational.

### Convergence trend

| Iteration | Blockers found | Advisories | Notes |
|---|---:|---:|---|
| v5.0 bootstrap | 12 | 3 | Drift audit |
| v5.1 drift fix | 7 | 3 | Drift audit |
| v5.2 drift fix | 11 | 3 | Exploit enumeration (new axis) |
| v5.3 bypass fix | 0 | 1 | Expected — next stop-hook may still find the boundary of honest-agent scope |

Next stop-hook iteration: if Codex finds more, they're either (a) further bypasses within honest-agent scope = routine fix, or (b) explicitly into malicious-fabrication territory = deferred per trust model.

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
