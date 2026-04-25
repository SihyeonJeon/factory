# REGULATION v5.9 — Sharp Round Orchestration Addendum

**Status:** Draft addendum for 2026-04-24 v5.9 orchestration. It becomes canonical only after the roadmap meeting is accepted and the active `REGULATION.md` is amended through the normal meeting path.

## §A. Main Operator / Orchestrator

- Codex GPT-5.5 acts as Main Operator + Orchestrator for round definition, defect decomposition, dependency graph, priority, and 3-axis verification protocol.
- Claude Code Operator remains an equal co-operator and assists with build/git/MCP/runtime evidence capture/user communication.
- This addendum does not remove the v5 invariant: Author ≠ Verifier.

## §B. Sharp Round Rule

Every user-visible defect must be decomposed as:

```
1 round = 1 defect = <= 3 acceptance criteria
```

Forbidden for v5.9 rounds:
- Broad "improve UX" briefs without a single defect target.
- Acceptance lists larger than 3.
- Closing a round from code review alone.
- Combining layout, feature, and process fixes into one implementation dispatch unless the user explicitly approves.

## §C. Three-Axis Verification

Before any round closes, a fresh Verifier Codex session must mark all three axes PASS:

| Axis | Required proof | Typical artifact |
|------|----------------|------------------|
| Code | Targeted code diff review against `spec.md` and affected line ranges | `context_harness/reports/<round_id>/evidence/code_review.md` |
| Runtime / Real Use | Simulator UITest, simulator smoke, or real-device smoke matching the user-visible defect | screenshots, xcresult, device note, video note |
| Process | Contract scope, evidence completeness, author/verifier separation, notes accuracy | `evidence/notes.md` + verifier checklist |

Rule:
- Any single-axis FAIL rejects the round.
- The verifier writes the reject reason into `context_harness/reports/<round_id>/evidence/notes.md`.
- The same round is redispatched with the same defect ID; do not silently roll the failure into a broad follow-up round.
- Only when Code PASS + Runtime PASS + Process PASS may Claude Code perform commit/push handoff.

## §D. Required Evidence Notes Shape

Each round must maintain:

```markdown
# <round_id> Evidence Notes

## Defect
- Defect ID:
- User-visible failure:
- Target files / line ranges:

## Code Axis
- Reviewer:
- Result: PASS | FAIL
- Evidence:
- Reject reason, if FAIL:

## Runtime Axis
- Device/simulator:
- Scenario:
- Result: PASS | FAIL
- Screenshot/video/xcresult:
- Reject reason, if FAIL:

## Process Axis
- Contract locked:
- Acceptance count <= 3:
- Author != verifier:
- Result: PASS | FAIL
- Reject reason, if FAIL:

## Handoff
- Commit/push delegated to Claude Code: yes | no
```

## §E. ASCII Protocol Diagram

```text
User defect
   |
   v
Codex Orchestrator decomposes one sharp round
   |
   v
spec.md (<=3 acceptance) + eval protocol + dependency note
   |
   v
Implementer Codex changes only whitelisted files
   |
   v
Evidence capture by Claude Code/runtime harness
   |
   v
Fresh Verifier Codex checks 3 axes
   |
   +--> Code FAIL --------+
   |                      |
   +--> Runtime FAIL -----+--> notes.md reject reason --> same round redispatch
   |                      |
   +--> Process FAIL -----+
   |
   v
Code PASS + Runtime PASS + Process PASS
   |
   v
Claude Code commit/push handoff
   |
   v
Round close + retro
```

## §F. P0 Runtime Standard

For P0 user-visible UI defects, runtime verification must use at least one of:
- Real-device smoke when the defect depends on Dynamic Island, safe area, share extension, or location permission.
- Simulator smoke with explicit device model and coordinate/permission setup when real-device capture is unavailable.

Skipping runtime verification is a FAIL, not an advisory.
