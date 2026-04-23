# Supabase E2E Setup

## Create The Test User

1. Open Supabase Dashboard -> Authentication -> Users.
2. Select Add user.
3. Enter the E2E email and password.
4. Use Dashboard-created users where possible because they bypass email confirmation.

If manual signup is used instead, disable confirmation for this project while creating the test account:

Supabase Dashboard -> Authentication -> Policies -> Email -> Confirm Email OFF.

## Environment Variables

Set both variables before running the E2E class:

```bash
export UNFADING_E2E_EMAIL="e2e@example.com"
export UNFADING_E2E_PASSWORD="replace-with-test-password"
```

The E2E tests skip cleanly when either variable is unset or empty.

## Run Only Supabase E2E

```bash
UNFADING_E2E_EMAIL=... UNFADING_E2E_PASSWORD=... \
xcodebuild test \
  -project MemoryMap.xcodeproj \
  -scheme MemoryMap \
  -destination 'platform=iOS Simulator,id=00FCC049-D60A-4426-8EE3-EA743B48CCF9' \
  -only-testing MemoryMapTests/SupabaseE2ETests
```

## Expected Coverage

- `testSignInAndFetchProfile` signs in with Supabase Auth and fetches the current user.
- `testCreateAndFetchGroupThenMemory` creates a group, creates a memory inside it, fetches group memories, and deletes the created memory.
