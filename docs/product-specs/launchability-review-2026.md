# Launchability Review — Final (2026-04-23)

Round: `round_e2e_testflight_r1`
Primary locale: Korean (`ko_KR`)
Signing status: `DEVELOPMENT_TEAM` is intentionally empty until Apple Developer enrollment provides a team ID.

## Final Status Table

| Area | Status | Notes |
|---|---|---|
| DB | CHECK | Supabase schema, RLS, repositories, and model tests are present for profiles, groups, memories, photos, and subscriptions. |
| Auth | CHECK | Email/password auth path is wired through Supabase; E2E sign-in coverage is skipped unless operator-provided credentials are present. |
| Groups | CHECK | Group create/join/fetch repository path and UI store are implemented; R24 E2E covers create group through Supabase RPC when credentials are configured. |
| Memories | CHECK | Memory create/fetch/delete repository path is implemented; R24 E2E covers group-scoped memory lifecycle when credentials are configured. |
| Photos | CHECK | Photo uploader and signed URL rendering are wired for launchability; production media quota and lifecycle policy remain future hardening. |
| Profile sync | CHECK | Profile preference sync path is present with local fallback coverage. |
| StoreKit | DEFER | Local StoreKit 2 paywall and entitlement state exist; Edge Function receipt validation remains deferred before paid backend quota enforcement. |
| Assets | DEFER | AppIcon and launch logo are wired, but current artwork is placeholder quality and needs professional branded replacement. |
| Privacy | CHECK | Info.plist privacy strings and PrivacyInfo manifest are present; App Store privacy answers still need final owner review. |
| E2E | CHECK | `SupabaseE2ETests` is added and skips cleanly unless `UNFADING_E2E_EMAIL` and `UNFADING_E2E_PASSWORD` are set. |

## Launch-Blocking External Actions

1. Supabase Dashboard -> Auth -> Policies -> enable HIBP leaked-password protection.
2. Apple Developer enrollment -> obtain Apple team ID and rerun archive with `scripts/archive.sh <TEAM_ID>`.
3. App Store Connect -> create app record, subscription products, privacy answers, screenshots, support URL, and privacy policy URL.
4. Commission professional AppIcon, launch logo, and marketing screenshot assets to replace the current placeholder art.

## Deferred Items

- Apple Sign in.
- Edge Function receipt validation through App Store Server API before granting high-cost storage or AI entitlements.
- Real-branded AppIcon and launch branding; current icon is a placeholder.
- Localized App Store metadata for Korean and English listings.
- Actual TestFlight build upload; blocked until Apple Developer team ID and signing are available.

## TestFlight Prep

- Archive helper: `workspace/ios/scripts/archive.sh`.
- Export template: `workspace/ios/scripts/export-options.plist`.
- Required command after enrollment:

```bash
cd workspace/ios
scripts/archive.sh <APPLE_TEAM_ID>
```

- Expected output: `.build/export/MemoryMap.ipa`.
- Current limitation: without a valid `DEVELOPMENT_TEAM`, archive/export cannot produce a signed TestFlight IPA.

## Screenshot Harvest

- Existing UITests attach named screenshots for map, calendar, rewind, settings, composer, group hub, and memory detail.
- Cleaner App Store-ready extraction helper: `workspace/ios/scripts/harvest_screenshots.sh <xcresult> [output_dir]`.
- Default output directory: `workspace/ios/AppStoreScreenshots`.
- Final App Store screenshots still require human curation for required device sizes and listing composition.

## E2E Setup

- Setup notes: `workspace/ios/scripts/e2e_setup.md`.
- E2E tests are safe in normal CI because they skip when credentials are absent.
- To run only the Supabase E2E class, provide `UNFADING_E2E_EMAIL` and `UNFADING_E2E_PASSWORD`.
