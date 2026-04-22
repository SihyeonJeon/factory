---
round: round_foundation_reset_r1
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round2-whitelist-project-yml
contract_hash: none
created_at: 2026-04-23T00:55:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---

# Meeting — Round 2 Whitelist Amendment: add project.yml

## Context

- Round `round_foundation_reset_r1` is in `close` phase
- `xcodebuild test` required adding `GENERATE_INFOPLIST_FILE: YES` to the `MemoryMapTests` target in `workspace/ios/project.yml` so the test bundle could sign
- `project.yml` was not in the round's base `file_whitelist.txt`
- Commit traceability on `close` flagged `workspace/ios/project.yml` as out-of-whitelist

## Decision

Amend `file_whitelist.txt` to add `workspace/ios/project.yml`. This is a minimal, additive amendment: `project.yml` edits in this round are strictly the test-target setting needed to run tests. No app-target or build-settings drift.

## Challenge Section

### Objection / Risk
Adding `project.yml` to the whitelist retroactively means any edit in this round is now accepted. Mitigation: the actual diff is a single-line `GENERATE_INFOPLIST_FILE: YES` addition to the test target; review confirmed no other changes.

### Rejected alternative
Revert the `project.yml` edit. Rejected — tests wouldn't run without the `INFOPLIST` setting, which invalidates the entire round's Gate 1 evidence.

### Uncertainty deferred
Future rounds may need broader project.yml edits (e.g., adding new Swift targets). A general "allow project.yml edits" rule will be considered at the next round's planning meeting.

## Amendment Detail

Amendment file: `file_whitelist.amendment.1.txt`
Target: `file_whitelist.txt`
Supersedes: `file_whitelist.txt` base whitelist (additive)

Amendment body adds one entry:
```
+workspace/ios/project.yml
```
