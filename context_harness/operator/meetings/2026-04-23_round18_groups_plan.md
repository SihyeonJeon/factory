---
round: round_groups_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r18-groups
contract_hash: none
created_at: 2026-04-23T11:30:00Z
codex_session_id: fresh
---
# R18 Groups + ActiveGroupStore + onboarding — plan & outcome

## Decision
Keep SampleGroup/SampleGroupMember in SampleModels for previews + UnfadingAvatarStack compatibility; map DBProfile→SampleGroupMember at the view boundary. This avoids a cascade refactor while unblocking cloud-backed groups.

## Challenge Section
### Objection
Could delete SampleGroup entirely and refactor UnfadingAvatarStack to take DBProfile. Rejected: too many preview/test callsites; invasive for a single round.

### Risk
GroupMode.general doesn't perfectly match DB mode "group" — Codex used a string map ("couple"/"group"). Accepted: string ↔ enum mapping is explicit in GroupStore.mode computed property.

### RPC signature
`create_group_with_membership(p_name, p_mode, p_intro, p_cover_color_hex)` — fifth arg default '#F5998C' always passed. OK.

## Outcome
111/111 tests pass (100 unit + 11 UITest). xcresult: `workspace/ios/.deriveddata/r18/Test-R18.xcresult`.
New: DBModels / GroupRepository / GroupOnboardingView / rewritten GroupStore + GroupHubView.
