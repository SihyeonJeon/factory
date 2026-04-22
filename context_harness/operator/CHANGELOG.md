# Operator CHANGELOG

Append-only. Every operator-doc amendment must add an entry with date, summary, and meeting pointer.

---

## v5.0 — Bootstrap (2026-04-19)

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
