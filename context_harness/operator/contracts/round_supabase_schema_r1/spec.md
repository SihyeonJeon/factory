# round_supabase_schema_r1 — Supabase schema gap + storage lockdown

**Round ID:** round_supabase_schema_r1
**Stage:** backend_schema (backend-only round under v5.7)
**Scope:** Supabase Postgres DDL + storage bucket config + RPCs. No Swift code.
**Owner-operator:** claude_code
**Verifier:** codex (evidence review, not code execution — backend is remote)

## Objective
Fill schema gaps required for iOS Unfading launchability without rewriting existing tables (R1–R14 reused `profiles/groups/group_members/memories/events/group_invitations/memory_reactions` unchanged). Specifically:

1. Add `groups.cover_color_hex` for hub visual tokens.
2. Add `subscriptions` table for StoreKit 2 entitlement mirror.
3. Lock `memories` storage bucket: public → private, 25MB limit, image/* MIME allowlist.
4. Add storage RLS for `memories` bucket (group-member gated by path prefix `<group_id>/...`).
5. Add helper RPCs: `create_group_with_membership`, `join_group_by_code`, `rotate_invite_code`.
6. Add trigger `bump_memory_reaction_count` to maintain `memories.reaction_count`.
7. Broaden `group_members_select` so users can see other members of their own groups.
8. Fix advisor: set `search_path` on `bump_memory_reaction_count`.

## Non-goals
- No `auth.users` schema changes.
- No Edge Functions (R22 scope).
- No client code.
- HIBP leaked-password toggle — dashboard-only, deferred to R17 closeout.

## Acceptance
- All migrations apply cleanly (idempotent with `if not exists` / `drop if exists`).
- `get_advisors security` returns 0 issues except the known HIBP dashboard toggle.
- Storage bucket `memories.public=false`, `file_size_limit=26214400`, MIME allowlist present.
- All four storage RLS policies present on `storage.objects` for `bucket_id='memories'`.
- All three RPCs callable by `authenticated` role (grant present).
