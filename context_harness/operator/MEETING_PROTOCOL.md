# MEETING_PROTOCOL — Harness v5

**Version:** v5.3
**Precedence:** Below OPERATOR.md (informational + template); but its enforcement points are normative and echoed in REGULATION §4.

---

## §1. What counts as a meeting

A **meeting** is a markdown file at `operator/meetings/<ISO>_<topic>.md` representing a written exchange between operators. All cross-operator coordination goes through meetings.

A meeting is NOT:
- A Bash command
- A commit message
- A code comment
- An inline prompt without frontmatter

If an operator tries to coordinate via anything other than a meeting file, the other operator should refuse and ask for a meeting file.

## §2. File name

`operator/meetings/YYYY-MM-DD_<kebab-topic>.md`

Examples:
- `2026-04-19_v5_kickoff.md`
- `2026-04-20_round1_spec_review.md`
- `2026-04-21_amend1_whitelist_expansion.md`

## §3. Required frontmatter (YAML)

```yaml
---
round: <round_id or "none">
stage: <one of: overall_planning, detailed_design, convention_lock, eval_protocol, acceptance, round_lock, coding_1st, runtime_capture, evaluation_verdict, gate2, coding_2nd, retro, regulation_update, operator_amendment, factual_verification>
status: draft | in_review | decided | escalated | abandoned
participants: [claude_code, codex]
decision_id: <short slug, unique per repo>
contract_hash: <sha256:... of active spec.md, or "none">
created_at: <ISO timestamp>
---
```

`decision_id` must be globally unique. Suggested format: `YYYYMMDD-<short-slug>`.

## §4. Required sections

```markdown
## Context
(≤5 bullets. File pointers only, not inline content dumps. Link hashes if referring to evidence.)

## Proposal (or Question)
(One clear position or one answerable question.)

## Questions
(Specific, answerable questions for the peer.)

## Counter / Review
(Peer's response. Added when peer replies — append, don't overwrite.)

## Convergence
(Iterative refinement. Each turn appended, not overwritten.)

## Decision
(Final decision + reasoning. Present only when status == decided.)

## Challenge Section
(See §5 below. Required for decision meetings. Must contain at least one of: objection, risk, rejected alternative, explicit uncertainty. For factual meetings, state: "No normative decision; verified facts only" + evidence refs.)
```

Optional sections:
- `## Mea Culpa` — if an operator acknowledges a prior mistake
- `## Escalation Path` — if moving to the escalation ladder (REGULATION §6)
- `## Amendment Detail` — for contract amendments, listing `supersedes` targets

## §5. Challenge Section Rule

This is the anti-hallucination tripwire.

**Decision meetings** (any meeting whose `stage` is normative: design, contract, planning, retro, regulation_update, operator_amendment) must include ≥1 of:

- **Objection**: a concrete disagreement with stated reasoning
- **Risk**: a named risk with mitigation or conscious acceptance
- **Rejected alternative**: an option considered and discarded, with why-not
- **Explicit uncertainty**: a residual unknown that was consciously deferred (must state where/when it will be resolved)

**Factual meetings** (stage: factual_verification, or purely status-check meetings) must state:

```
## Challenge Section

No normative decision; verified facts only.

Evidence:
- <file path> @ sha256:... — <what was verified>
- <command output log> — <what was verified>
```

**Forbidden:**
- Faking dissent ("I weakly disagree with N for the record") — if you have no real objection, it's factual
- Moving the objection to an unrecorded chat channel
- Deleting the Challenge Section after the decision

Gate 5 blocker: decision meeting missing Challenge Section, OR factual meeting missing evidence refs.

## §6. Flow

1. **Initiator drafts** the meeting file with frontmatter `status: draft` + Context + Proposal + Questions.
2. **Sends the prompt** to the peer:
   - Claude Code → Codex: `codex exec resume <session_id> "<prompt>"` with the file path + ask
   - Codex → Claude Code: replies in the same file under `## Counter / Review`; Claude Code reads it next turn
3. **Peer adds `## Counter / Review` section**, changes `status: in_review`.
4. **Iterate**: Convergence section gets appended with each exchange. Each turn must cite the specific claim it's addressing.
5. **Converge or escalate**:
   - Converge: decision + Challenge Section written. `status: decided`. One JSONL event appended to `docs/exec-plans/process-log.jsonl`.
   - Escalate: see REGULATION §6 ladder. `status: escalated`.
6. **Abandon** (rare): if the topic is withdrawn. `status: abandoned` + one-line reason. Evidence retained.

## §7. JSONL process-log event

At `decided` status:

```json
{"ts": "2026-04-19T14:22:00Z", "event": "meeting_decided", "meeting": "operator/meetings/2026-04-19_v5_kickoff.md", "round": "none", "stage": "operator_amendment", "participants": ["claude_code","codex"], "decision_id": "20260419-v5-bootstrap", "challenge_count": 7}
```

Appended — never overwrite.

## §8. Revival

A `status: decided` meeting is immutable. If a decision needs revisiting:
- Open a new meeting referencing the prior `decision_id` in Context
- If the new meeting supersedes the old decision, say so in Decision + update CHANGELOG

## §9. Codex CLI session lifecycle

- First call to Codex per meeting chain: `codex exec --sandbox read-only --skip-git-repo-check "<prompt>"` → capture `session id` from output.
- Subsequent turns in the SAME meeting chain: `codex exec --sandbox read-only --skip-git-repo-check resume <session_id> "<prompt>"`.
- Different meeting chain → new session. Don't cross-thread meetings.
- If Codex returns 401 or idle timeout: record in blackboard, re-run `/codex:setup`, consider escalation. Don't silently retry.

## §10. Templates

Template lives at `operator/meetings/_template.md` (created at bootstrap). Copy + fill frontmatter to start a new meeting.
