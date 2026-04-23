---
round: round_e2e_testflight_r1
stage: planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r24-e2e
contract_hash: none
---

## Context

- R24 is the final launchability verification and TestFlight preparation round for the current beta-unnecessary launchable state.
- `DEVELOPMENT_TEAM` is empty, so signed archive and actual TestFlight upload require user Apple Developer enrollment.
- Existing UITests already attach named screenshots; the round needs a cleaner extraction path for App Store prep.
- Supabase E2E coverage must be safe for normal test runs and only execute with explicit operator credentials.
- StoreKit is locally launchable, while receipt validation remains a deferred backend security item.

## Proposal

- Add `SupabaseE2ETests` to `MemoryMapTests` with `XCTSkipIf` on missing `UNFADING_E2E_EMAIL` or `UNFADING_E2E_PASSWORD`.
- Use current repository APIs for group and memory E2E lifecycle coverage.
- Add archive/export scripts for a future Apple team ID.
- Add E2E setup notes and a UITest screenshot harvest helper.
- Rewrite the launchability review as a final status table with explicit deferred launch actions.

## Questions

- Can this round produce a signed TestFlight IPA?
  - Decision: no. The user must complete Apple Developer enrollment and provide a team ID first.
- Should E2E tests create live Supabase data in default CI?
  - Decision: no. They must skip unless explicit credentials are present.

## Counter / Review

- Risk: The E2E group object is left behind because the repository currently exposes memory deletion but no group deletion helper. This is acceptable for low-frequency operator E2E and should use a dedicated test account/project.
- Risk: `DEVELOPMENT_TEAM` remaining empty means archive prep can only be documented and scripted, not fully verified as a signed IPA.
- Risk: Screenshot extraction from `.xcresult` depends on Xcode's current `xcresulttool` JSON shape; keep the helper bounded and document manual curation as still required.

## Convergence

- Proceed with skipped-by-default E2E and focused archive documentation.
- Treat Apple account, App Store Connect, and professional assets as user-owned external dependencies.
- Keep the final checklist explicit about CHECK versus DEFER so launch state is not overstated.

## Decision

Implement `round_e2e_testflight_r1` with skipped Supabase E2E tests, archive/export helpers, E2E setup notes, screenshot harvest support, final launchability review, and evidence notes for deferred external actions.

## Challenge Section

- Challenge: Calling the app "launchable" must not imply upload-ready. Without a team ID and App Store Connect setup, this round can only prepare commands and templates for TestFlight.
- Rejected alternative: force-running live E2E in the normal suite. That would make local and CI test reliability depend on secrets and mutable remote state.
- Rejected alternative: client-side StoreKit entitlement as backend quota authority. Paid storage or AI features must wait for server-validated receipt handling.
