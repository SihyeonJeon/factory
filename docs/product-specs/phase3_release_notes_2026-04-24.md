# Phase 3 Release Notes — 2026-04-24

Audience: internal device verification / TestFlight pre-upload review
Build line: R26-R50 integrated

## What Changed

### Core product surface

- Custom 3-tab shell, rebuilt bottom sheet, home chrome, overlays, composer, memory detail, calendar dial, rewind stories, and group hub/settings flows are all in the unified app line.
- Marker selection, filtered detail entry, map theme selection, search, and export surfaces are now part of the same beta build line.

### Data and account hardening

- Real-data wiring remains connected to Supabase-backed groups, memories, profiles, and related flows.
- Native Sign in with Apple client wiring is present in-app.
- Subscription sync/client-side StoreKit server handoff wiring landed for backend reconciliation prep.
- Realtime incoming-memory handling and offline queue support are present for unstable network conditions.

### Device verification helpers

- `scripts/archive.sh` and `scripts/export-options.plist` remain the archive/export entrypoints for a signed TestFlight run.
- Phase 3 final reran the requested simulator regression command with `.deriveddata/r50/Test-R50.xcresult`.
- The rerun did not execute tests in this sandbox because CoreSimulator and SwiftPM network resolution were unavailable; the last green baseline remains `229` total / `215` passed / `14` skipped / `0` failed from `round_data_export_r1`.

## Real-Device Checks

1. Verify Apple Sign in launches and returns to the correct signed-in shell on a physical device with provider credentials configured.
2. Open map, calendar, rewind, settings, search, map-theme selection, and export surfaces in one pass to confirm there is no navigation regression after R41-R49.
3. Confirm composer save gating, marker-to-detail navigation, and group switching still behave correctly on device.
4. Trigger StoreKit paywall and confirm entitlement/sync surfaces update without placeholder dead ends.
5. Run one real signed archive/export/upload flow after team ID and App Store Connect setup are complete.

## Known Deferred

- App Store Connect product registration
- Apple Developer team ID assignment
- Supabase HIBP leaked-password protection toggle
- Real-device TestFlight archive/export/upload
