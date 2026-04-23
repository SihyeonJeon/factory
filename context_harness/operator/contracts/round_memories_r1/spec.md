# round_memories_r1 — MemoryStore to Supabase + realtime

**Round ID:** round_memories_r1
**Stage:** coding_1st
**Scope:** iOS memory persistence migration from local draft JSON to Supabase-backed memories with realtime group filtering and offline read cache.
**Owner-operator:** codex
**Verifier:** claude_code

## Objective

Wire the existing memory surfaces to the R15/R16 Supabase schema and service layer:

1. Add `DBMemory` and `DBMemoryInsert` models matching `public.memories` snake_case columns.
2. Add `MemoryRepository` with a Supabase implementation for fetch/create/update/delete.
3. Replace the local-draft `MemoryStore` with a cloud-backed store that exposes `memories`, `state`, CRUD methods, group-scoped realtime subscription, and per-group offline cache.
4. Preserve compatibility for existing UI by exposing `legacyDrafts` and `drafts` as computed `[SampleMemoryDraft]`.
5. Wire composer save through `AuthStore`, `GroupStore`, and `MemoryStore` so inserts include authenticated user id and active group id.
6. Start memory load and realtime subscription after `activeGroupId` is known; cancel and resubscribe when the active group changes.
7. Populate memory stubs when `-UI_TEST_GROUP_STUB` is enabled so screenshot paths retain content.
8. Add repository-backed unit tests and JSON round-trip tests for memory DB models.

## Non-goals

- Photo upload/storage path wiring. Composer inserts empty `photo_urls` this round.
- Full map/calendar/rewind refactor from sample pins/moments to DB memory rendering.
- Conflict resolution beyond id-based dedup and last event wins.
- Backend schema, RLS, or storage policy changes.

## Acceptance

- All DB-touching memory code goes through `MemoryRepository`.
- `MemoryStore.loadMemories(for:)` fetches from Supabase, writes `memory-cache-<groupId>.json`, and falls back to cache on fetch error.
- `MemoryStore.subscribeRealtime(groupId:)` subscribes to `public.memories` INSERT/UPDATE/DELETE with `group_id=eq.<id>` filter and mutates `memories` on the main actor.
- Create/update/delete mutate the published memory list locally and tolerate realtime echo by id-based dedup.
- Existing `.drafts` callsites continue compiling via computed alias.
- Composer save throws user/group errors instead of writing without required RLS fields.
- UI test group stub path creates 2-3 `DBMemory` rows.
- Tests cover create/update/delete/load-empty/cache fallback plus `DBMemory`/`DBMemoryInsert` JSON shape.
- `xcodegen generate` succeeds.
- Requested `xcodebuild test` is attempted; if SPM fetch is blocked by sandbox networking, capture the failure and leave code/artifacts staged.
