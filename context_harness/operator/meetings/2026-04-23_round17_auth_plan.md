---
round: round_auth_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r17-auth
contract_hash: none
created_at: 2026-04-23T11:00:00Z
codex_session_id: fresh
---
# R17 email/password auth — plan & outcome

## Context
First real cloud-backed round. Unblocks multi-device real identity.

## Decision
Email/password only for now. Apple Sign in deferred — App Store 4.8 requires it only when third-party social login is offered, which we don't.

## Challenge Section
### Objection
Apple Sign in polish? Deferred. Adds capability setup / Services ID in Supabase / entitlements. R22+.

### Risk
HIBP leaked-password protection is OFF (R15 advisor carry-over). Accepted for launch-gate; operator action item: toggle in Supabase Dashboard → Auth → Policies.

### UI-test bypass
Previous `-UI_TEST_SKIP_ONBOARDING` now insufficient since auth is the new root. Added `-UI_TEST_AUTH_STUB` (forces .signedIn stub) and `-UI_TEST_RESET_DEFAULTS` (clears UserDefaults) so UITests can exercise both the signed-in and signed-out paths.

## Outcome
104/104 tests pass (96 unit + 8 UITest, +7 new vs R16). xcresult: `workspace/ios/.deriveddata/r17/Test-R17.xcresult`.

## Operator action item
- Supabase Dashboard → Auth → Policies → enable "Leaked password protection (HaveIBeenPwned)"
