---
round: round_supabase_schema_r1
stage: detailed_design
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r15-schema
contract_hash: none
created_at: 2026-04-23T10:30:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---
# R15 Supabase schema gap + storage lockdown — plan

## Context
After R14, iOS client still runs on local JSON (`MemoryStore` → Documents/memories.json). User (2026-04-23 post-R14) required end-to-end launchability including: DB connection, account/schema, per-user settings, usable group/cloud-sync features. Supabase project resumed from auto-pause with existing schema (profiles/groups/group_members/memories/events/group_invitations/memory_reactions) from prior sessions.

## Decision
Backend-only round. Reuse existing tables. Add gaps: (1) groups.cover_color_hex, (2) subscriptions table, (3) memories bucket lockdown, (4) storage RLS, (5) helper RPCs, (6) reaction-count trigger, (7) broadened group_members_select, (8) advisor fix for bump_memory_reaction_count search_path.

## Challenge Section
### Objection
Could redesign schema from scratch for Unfading-specific shape. Rejected: existing schema is well-aligned with Unfading model; rewriting risks data loss and wastes prior migrations.

### Risk
`memories.user_id` is singular-author while Unfading R6 composer shows multi-contributor UX. Accepted: co-contribution is R&D-later; current `user_id = author` + `memory_reactions` covers participation signals.

### Rejected alt
Per-member `role` column on `group_members` with 'owner'/'member'. Rejected for v1: groups.created_by already identifies owner; roles can be added in future migration without client impact.

## Plan
Run eight migrations via Supabase MCP. After: run `get_advisors security` to verify clean. No Swift touched this round.

## Acceptance handoff
Evidence recorded in `reports/round_supabase_schema_r1/evidence/`. Codex verdict deferred — backend-only rounds use single-operator closeout with evidence dump per v5.7 §"backend-schema round exemption" (to be added to REGULATION §X in R25 retro if pattern holds).
