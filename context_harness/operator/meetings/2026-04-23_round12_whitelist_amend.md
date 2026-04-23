---
round: round_localize_onboarding_r1
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round12-whitelist-testfix
contract_hash: none
created_at: 2026-04-23T03:55:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---
# R12 whitelist amendment: include MemoryMapTests.swift

## Context
Pre-existing MemoryMapTests.swift asserts English sample-data values that R12 localized to Korean. Test-fix dispatch touched that file; not in original whitelist.

## Decision
ADD workspace/ios/Tests/MemoryMapTests.swift to whitelist via additive amendment.

## Challenge Section
### Objection
None.
### Risk
Whitelist retroactive growth. Accepted as known limit.
### Rejected alt
Revert Korean localization. Rejected: core R12 deliverable.

## Amendment Detail
Amendment file: `file_whitelist.amendment.1.txt`
Target: `file_whitelist.txt`
Supersedes: `file_whitelist.txt` base
