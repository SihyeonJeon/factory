---
round: round_group_ux_r1
stage: overall_planning
status: draft
participants: [claude_code, codex]
decision_id: 20260423-r25-group-ux
contract_hash: none
created_at: 2026-04-23T00:00:00+09:00
---

## Context

- User reported group creation only showed `잠시 후 다시 시도해주세요.`; server-side root cause was `gen_random_bytes` search_path and has been fixed by operator migration.
- Supabase group RPC signatures now accept optional `p_nickname`; client calls must be compatible.
- Backend now provides `update_group_name` for owners and `set_group_nickname` for the current member row.
- Target iOS files are listed in `contracts/round_group_ux_r1/file_whitelist.txt`.

## Proposal

Implement R25 as a narrow compatibility and UX round:

- Update Swift DB models and repository protocol to match the deployed Supabase group surface.
- Load group roster rows as membership row + joined profile so nickname can be displayed and edited.
- Add optional nickname input during create/join.
- Add owner-only group name editing and member nickname editing in Group Hub.
- Improve onboarding RPC failure messages by appending a 120-character actual error suffix while preserving the existing fallback phrase.

## Questions

- Should owner-only group name editing be enforced only in UI, or should `GroupStore` also accept current-user context?
- Should join RPC errors still map to `invalidCode`, or should they use the same debug-visible suffix pattern as create errors?

## Counter / Review

Pending Claude Code Operator review.

## Convergence

Pending.

## Decision

Pending.

## Challenge Section

Risk: exposing raw RPC error descriptions can surface implementation details in the UI. Mitigation: the suffix is truncated to 120 characters, while full error output is limited to DEBUG prints.

Rejected alternative: keep mapping join failures to `invalidCode`. This hides non-code backend failures in the same way the create flow hid the `gen_random_bytes` search_path failure, so the implementation uses the suffix pattern for post-precheck join failures too.

Explicit uncertainty: the final operator lock/review status is deferred until Claude Code Operator reviews the draft meeting and artifacts.
