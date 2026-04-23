---
round: round_memories_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r19-memories
contract_hash: none
created_at: 2026-04-23T03:17:21Z
codex_session_id: fresh
---
# R19 MemoryStore → Supabase + realtime — plan & outcome

## Context
- R15/R16 provide `public.memories` columns, RLS, and `SupabaseService.shared.{database,realtime}`.
- R18 provides `GroupStore.activeGroupId`, group stubs, and authenticated UI-test path.
- Existing UI still reads sample pins/moments and `memoryStore.drafts` in Settings.
- This round migrates persistence first while preserving those sample-backed presentation surfaces.

## Proposal
Add DB memory models and a repository, rewrite `MemoryStore` around Supabase CRUD plus group-scoped realtime, and keep computed legacy drafts for compatibility. Wire composer save to `AuthStore` + `GroupStore` + `MemoryStore`; wire app startup/group switch to load and resubscribe.

## Questions
- Should composer block on missing photo upload? Answer: no, photo storage is deferred; insert empty `photo_urls`.
- Should calendar/rewind switch fully to DB rows? Answer: not in this round; persistence path is the acceptance target.

## Counter / Review
### Objection
Realtime could subscribe to all memory events and filter client-side. Rejected: the group id is available and server-side filter reduces event volume while matching RLS intent.

### Risk
Delete realtime payloads depend on replica identity for a full old row. The store attempts to decode `oldRecord` as `DBMemory`; if backend only sends primary key, delete events will log a decode failure and rely on local delete mutation until a reload. Accepted for R19; evidence notes call this out.

### Risk
Composer uses the selected place string with default Seoul coordinates because place search is still a placeholder. Accepted: schema requires non-null coordinates and full place geocoding is out of scope.

## Convergence
Proceed with repository-only DB access, group-filtered realtime, id-based upsert dedup, and offline cache fallback. Leave sample map/calendar/rewind visuals in place except where direct `MemoryStore` compatibility is required.

## Decision
Implement R19 as a persistence and sync layer round, not a full UI data-model refactor. `MemoryStore.drafts` remains a computed alias over `legacyDrafts` so existing callsites do not break.

## Challenge Section
Normative decision recorded: use server-side realtime filter `group_id=eq.<activeGroupId>` and cancel/resubscribe on group switch. Rejected alternative: one global channel for all groups because it expands filter cardinality to the client and makes leak semantics harder to reason about.

## Outcome
Implemented DB memory models, repository, rewritten `MemoryStore`, composer save wiring, app group-sync wiring, UI-test memory stubs, and memory model/store tests.

`xcodegen generate` succeeded.

Requested `xcodebuild test` stopped before compilation with exit code 74 because the sandbox could not resolve GitHub hosts for SPM packages (`Could not resolve host: github.com`). CoreSimulatorService was also unavailable in this environment.
