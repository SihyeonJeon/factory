# round_e2e_testflight_r1 Spec

## Goal

Finish R24 launch-readiness verification by adding skipped-by-default Supabase E2E coverage, TestFlight archive documentation, App Store screenshot harvest support, and the final launchability checklist.

## Scope

- Add `SupabaseE2ETests` under the existing `MemoryMapTests` target.
- Skip E2E tests unless `UNFADING_E2E_EMAIL` and `UNFADING_E2E_PASSWORD` are present.
- Cover Supabase sign-in, current user fetch, group creation, memory creation, memory fetch, and memory deletion.
- Add TestFlight archive helper script and export options plist template.
- Add E2E setup operator notes for creating the Supabase test user and running the focused test class.
- Add a screenshot harvest helper that extracts UITest PNG attachments from an `.xcresult` bundle into `AppStoreScreenshots`.
- Rewrite the launchability review as the final 2026-04-23 status checklist.
- Record deferred user actions caused by external account, signing, App Store Connect, and asset dependencies.

## Non-Goals

- No signed archive or IPA upload in this round because `DEVELOPMENT_TEAM` is empty.
- No Apple Developer enrollment automation.
- No App Store Connect product creation automation.
- No production Apple Sign in implementation.
- No Edge Function receipt validation implementation.
- No replacement of the placeholder AppIcon with final brand artwork.

## Acceptance

- The project regenerates through `xcodegen generate`.
- Full `xcodebuild test` completes with the new E2E tests skipped when credentials are absent.
- `scripts/archive.sh` is executable and accepts `<TEAM_ID> [SCHEME]`.
- `scripts/export-options.plist` uses App Store Connect export settings.
- `scripts/e2e_setup.md` documents Supabase test user setup, environment variables, and focused test invocation.
- `docs/product-specs/launchability-review-2026.md` lists final CHECK/DEFER/TODO launchability status and external deferred actions.
