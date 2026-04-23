# round_profile_sync_r1 Spec

## Context

R21 adds cloud sync for user profile preferences after the Supabase schema gained `profiles.preferences jsonb not null default '{}'::jsonb`. Existing RLS permits the signed-in user to update `display_name`, `photo_url`, and `preferences`.

## Scope

- Add a typed `DBProfilePreferences` model with local defaults for missing JSON.
- Extend `DBProfile` to decode and encode `preferences` while preserving compatibility with rows that omit the column.
- Add a `ProfileRepository` abstraction and Supabase implementation for current profile fetches plus display name, photo URL, and preference updates.
- Rewrite `UserPreferences` as the single local mirror for onboarding, profile display fields, and preferences.
- Sync preferences and display name from local state to Supabase using cancellable 500 ms debounce tasks.
- Bootstrap the local mirror from cloud profile data after auth transitions to `.signedIn(userId)`.
- Surface profile display-name editing and signed-in email in Settings.
- Add focused unit tests for DB profile preference coding, bootstrap, and debounced preference pushes.

## Non-Goals

- Offline retry queue beyond preserving local state on cloud write failure.
- Photo upload or photo URL editing UI.
- Supabase schema migration, already applied before this round.

## Acceptance

- `UserPreferences.init` does not perform network work.
- Existing `UserPreferences(userDefaults:forceHasSeenOnboarding:)` call sites and tests remain source-compatible.
- Cloud write failures are logged and do not roll back local `@Published` values.
- Rapid preference changes cancel the previous debounce task and result in a single repository update.
- Settings new profile strings are Korean.
- New Settings controls preserve a minimum 44 pt row height.
