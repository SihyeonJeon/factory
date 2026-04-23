# Launchability Review — Phase 2 Final (2026-04-24)

Round: `round_phase2_final_r1`
Primary locale: Korean (`ko_KR`)
Build target: `MemoryMap`
Signing status: `DEVELOPMENT_TEAM` remains empty until Apple Developer team enrollment is available.

## Integrated Scope

- Phase 1 complete: R26-R30 design token, shell, sheet, chrome, and overlay rebuild landed.
- Phase 2 complete: R31-R35 composer, memory detail, calendar dial/plans, rewind stories, and group hub/settings landed.
- Phase 2.5 complete: R36-R39 ship assets, storekit/paywall, launchability/TestFlight prep, and final stabilization landed.

## Status Table

| Area | Status | Notes |
|---|---|---|
| Design shell | CHECK | Custom 3-tab shell, home FAB, top chrome, filter chrome, and rebuilt bottom sheet are integrated from R26-R30. |
| Composer | CHECK | Phase 2 composer rewrite supports place confirmation, event binding, participants, emotions, and optional cost fields. |
| Memory detail | CHECK | Sprint 28 detail structure, same-event carousel, meta strip, and inline extra-note UI are present. |
| Calendar | CHECK | Calendar tab includes month picker, day detail, and general-group plan card flow. |
| Rewind | CHECK | Rewind stories flow and home curation entry are wired with deterministic sample aggregation. |
| Group hub / settings | CHECK | Settings entry, group overview, member state, invite placeholders, and notification toggles are integrated. |
| Supabase core | CHECK | Auth, groups, memories, photos, and profile sync remain wired from earlier rounds. |
| StoreKit local flow | CHECK | Local StoreKit paywall and entitlement surfaces exist for device verification. |
| Archive helper | CHECK | `workspace/ios/scripts/archive.sh` passes shell syntax validation. |
| Export options | CHECK | `workspace/ios/scripts/export-options.plist` passes `plutil -lint`. |
| Screenshot harvest helper | CHECK | Helper script is present and syntactically valid; R40 extraction did not yield screenshots because the test bundle never started. |
| Final simulator regression | BLOCKED | R40 `xcodebuild test` created an `.xcresult` bundle but failed before test execution in this sandbox due CoreSimulator unavailability and denied writes to `/Users/jeonsihyeon/.cache` / `~/Library/Caches`. |
| Signed archive / TestFlight upload | DEFER | Still blocked on Apple team ID, signing, and a real upload pass. |

## R40 Verification Snapshot

- Requested command executed:

```bash
cd /Users/jeonsihyeon/factory/workspace/ios
xcodebuild test \
  -project MemoryMap.xcodeproj \
  -scheme MemoryMap \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath .deriveddata/r40 \
  -resultBundlePath .deriveddata/r40/Test-R40.xcresult
```

- Test inventory in source: 176 unit tests + 28 UITests = 204 test methods.
- Executed tests in this sandbox: 0.
- `xcresult` status: `failedToStart`.
- Screenshot harvest status: attempted with `scripts/harvest_screenshots.sh`, but no PNGs were exported for R40 evidence.

## Phase 3 Deferred (R41-R50)

| Item | Target | Reason |
|---|---|---|
| Apple Sign in | R41-R50 | Required launch hardening item not implemented in current beta scope. |
| Edge Function receipt validation | R41-R50 | Needed before backend-enforced paid quota or AI/storage entitlement trust. |
| HIBP leaked-password toggle | R41-R50 | External Supabase dashboard action; not codified in-app. |
| Real TestFlight upload | R41-R50 | Requires Apple Developer team ID, signing, archive, export, and App Store Connect upload. |

## External Owner Actions

1. Apple Developer enrollment and team ID issuance.
2. App Store Connect app record, subscriptions, privacy answers, screenshots, support URL, and privacy policy URL.
3. Professional AppIcon / launch branding replacement and final store metadata.
4. Real device smoke plus signed TestFlight upload after signing prerequisites are available.

## Evidence

- R40 evidence: `context_harness/reports/phase2_final/evidence/`
- Archive helper: `workspace/ios/scripts/archive.sh`
- Export plist: `workspace/ios/scripts/export-options.plist`
