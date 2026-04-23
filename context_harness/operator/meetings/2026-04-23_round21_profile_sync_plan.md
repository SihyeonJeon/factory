---
round: round_profile_sync_r1
stage: implementation_plan
status: decided
participants: [human, codex]
decision_id: 20260423-r21-profile
contract_hash: none
---

## Context

- Supabase `profiles.preferences` exists as non-null JSONB with default `{}`.
- Existing RLS allows self-updates to display name, photo URL, and preferences.
- Current `UserPreferences` is local-only and Settings owns a separate instance.
- R21 requires cloud bootstrap after auth and debounced bidirectional updates.

## Proposal

- Add `ProfileRepository` so `UserPreferences` can sync through Supabase in production and a mock in unit tests.
- Keep local `UserDefaults` as the offline-authoritative mirror.
- Bootstrap only after `.signedIn(userId)` so init remains network-free.
- Use cancellable 500 ms `Task` debounce per profile field family.

## Questions

- Should failed cloud writes roll back local state?
- Should Settings own its own preferences object or use the app-level object?

## Counter / Review

- Rollback on failed write would violate offline use and could erase a user's latest local intent.
- A Settings-local object would split the preference source of truth from app bootstrap and auth sync.

## Convergence

- Local state remains authoritative; failed writes are logged only.
- The app-level `UserPreferences` is injected through the environment for Settings.

## Decision

Implement R21 profile sync with app-level `UserPreferences`, Supabase `ProfileRepository`, post-auth bootstrap, and cancellable 500 ms debounced cloud writes.

## Challenge Section

Rejected alternative: write directly from Settings to Supabase on every field edit. That approach couples UI to persistence, makes tests brittle, and risks excessive writes while the user is typing.
