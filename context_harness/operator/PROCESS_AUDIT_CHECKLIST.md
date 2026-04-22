# PROCESS_AUDIT_CHECKLIST — Harness v5

**Version:** v5.5
**Use:** Fill this out at Gate 5 before closing a round. Also run `harness/check_operator_round.py gates <round>` and attach its output.

---

## Gate 5 — Process Integrity

### Blockers (round cannot close if any fail)

- [ ] Every commit in this round is traceable to the active lock (lock `started_at` ≤ commit ts ≤ `closed_at` or now; commit touches only whitelisted files)
- [ ] No edit to any base contract file after lock creation (verified by hash match in lock)
- [ ] Every decision meeting (`stage` in normative set) has a non-empty Challenge Section
- [ ] Every factual meeting (`stage: factual_verification` or equivalent) has at least one evidence reference
- [ ] Every new operator/* file created this round is indexed in `FILE_INDEX.md`
- [ ] Line-count caps honored: `AGENTS.md` ≤80, `.claude/CLAUDE.md` ≤80, `OPERATOR.md` ≤120, `FILE_INDEX.md` ≤250
- [ ] `harness/check_operator_round.py gates <round>` exits 0
- [ ] `harness/check_operator_round.py audit-operator-layer` exits 0 (stage IDs + pointers only — role matrix full consistency NOT enforced in v5.x; see REG §7)
- [ ] No legacy doc was cited in this round's meetings to override a v5 operator doc
- [ ] Lock `status` is `active` (ready for transition to `closed`); not `paused`, `escalated`, or `aborted`
- [ ] If any Gate 1-4 had a remediation: its remediation meeting exists and was reviewed

### Advisories (record in retro; do NOT block close)

- [ ] `SKILLS.md` update decision classified in retro (append OR explicit "no novel pattern")
- [ ] `SESSION_RESUME.md` updated within last 48h
- [ ] `process-log.jsonl` event count matches decision meeting count
- [ ] `FILE_INDEX.md` line count: warn at configured threshold (currently 225), block above cap (250)
- [ ] Operator loaders (`.claude/CLAUDE.md`, `AGENTS.md`) both exist and point to `operator/OPERATOR.md`
- [ ] If any meeting went through escalation ladder: ladder tier path recorded

## Output Quality — Gates 1-4 (from v4, retained)

### Gate 1 — Build & Test
- [ ] `xcodegen generate` succeeds
- [ ] `xcodebuild test` zero failures
- [ ] Test count ≥ baseline from SESSION_RESUME.md (currently 140)

### Gate 2 — 3-Evaluator Review
- [ ] `red_team_reviewer` report produced and non-empty
- [ ] `hig_guardian` report produced and non-empty
- [ ] `visual_qa` report produced and non-empty

### Gate 3 — Cross-Agreement
- [ ] For every file flagged by 2+ evaluators: fix verified OR explicit override meeting with Challenge Section
- [ ] For every file flagged by 1 evaluator: fix OR documented disagreement

### Gate 4 — Process Metrics
- [ ] Remediation cycles this round ≤ 2
- [ ] BLOCKER recurrence (same BLOCKER type repeating): 0
- [ ] Brief-accuracy ≥ 90% (dispatches that didn't need whitelist amendment)
- [ ] SKILLS.md reference miss-rate ≤ 5% (dispatches that ignored a relevant S-*)

## Retro — mandatory content

Even if Gate 5 passes, the retro meeting must include:

- [ ] What Performer missed (both stages' performers, 1 line each)
- [ ] What Cross-Validator caught late (both stages' cross-validators, 1 line each)
- [ ] One durable lesson OR explicit "no novel pattern identified"
- [ ] Regulation debt: any rule that was cited but didn't actually enforce what it was meant to
- [ ] Operator-layer debt: any contradiction or staleness found in OPERATOR/STAGE_CONTRACT/REGULATION during the round
- [ ] Next-round readiness: does SESSION_RESUME.md reflect the true state?

---

## How to use this file

1. Copy it to `round_retro/<round_id>.md`
2. Check each box with evidence or a short note
3. Attach checker output at the bottom
4. Review meeting: both operators sign the retro (frontmatter `participants: [claude_code, codex]`)
5. On all blockers green: run `harness/check_operator_round.py close <round_id>` — checker re-verifies gates and writes `status: closed` + `closed_at`

## Amendment

Changes to this checklist are a REGULATION amendment (see REGULATION §11). Don't edit boxes silently between rounds.
