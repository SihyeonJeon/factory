# Supabase Schema Reference

**Project ref:** umkbjxycdgfhgwcnfbmo
**Last updated:** 2026-04-14

## Tables (7 total, all RLS enabled)

| Table | iOS Domain Model | Key Columns |
|-------|-----------------|-------------|
| `profiles` | User | id, email, display_name, photo_url |
| `groups` | DomainGroup | id, name, mode, intro, invite_code, created_by |
| `group_members` | membership | group_id, user_id |
| `group_invitations` | GroupInvitation | group_id, code, issued_at, expires_at |
| `events` | DomainEvent | group_id, title, start_date, end_date, is_multi_day |
| `memories` | DomainMemory | group_id, event_id, note, place_title, location, emotions[], cost, captured_at, reaction_count |
| `memory_reactions` | reactions | memory_id, user_id, emoji |

## Indexes (9 total)

- group_members(user_id), group_members(group_id)
- events(group_id), events(start_date)
- memories(group_id), memories(event_id), memories(captured_at), memories(geohash)
- group_invitations(code)

## RLS Policies

All tables enforce user-scoped access via `auth.uid()` and group membership checks.
