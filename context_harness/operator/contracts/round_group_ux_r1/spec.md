---
round: round_group_ux_r1
stage: detailed_design
author: codex
created_at: 2026-04-23T00:00:00+09:00
---

# R25 Group UX Extension + RPC Compatibility Spec

## Scope

Implement the client-side counterpart for the R15 Supabase group RPC signature update and expose the requested group UX affordances:

- Create/join group calls send optional member nickname via `p_nickname`.
- Group member roster decodes `group_members.nickname` joined with `profiles(*)`.
- Owners can rename a group through `update_group_name`.
- Any member can set their own group-local nickname through `set_group_nickname`.
- Group onboarding errors keep the existing Korean user-facing fallback while appending a short actual error description for operations/debugging.

## Backend Contract

The Supabase schema/RPC surface is assumed to be already deployed:

- `public.group_members.nickname text`
- `create_group_with_membership(p_name text, p_mode text default 'couple', p_intro text default null, p_cover_color_hex text default '#F5998C', p_nickname text default null) -> public.groups`
- `join_group_by_code(p_code text, p_nickname text default null) -> public.groups`
- `update_group_name(p_group_id uuid, p_name text) -> public.groups`
- `set_group_nickname(p_group_id uuid, p_nickname text) -> public.group_members`

## Implementation Requirements

- Add `nickname` to `DBGroupMember`.
- Add `DBGroupMemberWithProfile` for `group_members` rows selected with `profiles(*)`.
- Replace roster fetching with `fetchMembersWithNicknames(groupId:)`.
- Extend `GroupRepository` with create/join nickname parameters and the two new RPC methods.
- Convert `GroupStore.members` to `[DBGroupMemberWithProfile]`, add `memberProfiles`, and display nickname before profile display name.
- Add `GroupStore.updateGroupName(_:)` and `GroupStore.setMyNickname(_:)` with local state updates after RPC success.
- Add optional nickname fields to create and join onboarding forms, limited to 40 characters.
- Add owner-only group name edit affordance in the group hub using `AuthStore.currentUserId`.
- Add member nickname edit affordance in the group hub, 44pt minimum hit target.
- Keep invite-code rotate behavior intact.
- Add Korean localized strings for all new user-visible copy.

## Error Handling

For create/join RPC failures after local pre-checks pass, preserve:

`UnfadingLocalized.Groups.actionFailed`

Then append a parenthesized `String(describing: error)` suffix truncated to 120 characters. Debug builds should also print the full error for local investigation.

Local pre-check failures remain unchanged:

- Empty create name disables/blocks create.
- Invalid join code continues to show `invalidCode`.

## Testing Requirements

- Existing tests continue passing.
- `GroupStoreTests` covers create signature update, group-name local update, member nickname local update, and nickname-first display names.
- `DBModelsTests` covers `DBGroupMember.nickname` round-trip and joined `DBGroupMemberWithProfile` JSON round-trip.
- E2E compile surface is updated for the new create RPC signature.
