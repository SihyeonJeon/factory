# round_auth_r1 — email/password auth via Supabase

**Stage:** coding_1st
**Scope:** AuthStore + AuthLandingView + root branching + UI-test stub.
**Apple Sign in:** DEFERRED (not required by App Store 4.8 without third-party social login).

## Acceptance
- AuthStore @MainActor ObservableObject bootstraps from `SupabaseService.shared.client.auth.session`.
- AuthLandingView: 로그인/회원가입 segmented, email+password, reset-password sheet, 44pt a11y targets, Korean UI.
- MemoryMapApp root branching: unknown → spinner, signedOut → AuthLandingView, signedIn+!onboarded → OnboardingView, signedIn+onboarded → RootTabView.
- SettingsView accountSection shows signed-in email + sign-out button.
- UI-test stub: `-UI_TEST_AUTH_STUB` flag forces `.signedIn` stub; `-UI_TEST_RESET_DEFAULTS` clears UserDefaults.
- 104/104 tests pass (96 unit + 8 UITest).
