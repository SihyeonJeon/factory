# Launchability Review — Phase 4 Final (2026-04-24)

Round: `round_phase4_final_r1`
Primary locales: Korean / English (`ko`, `en`)
Build target: `MemoryMap`
Signing status: `DEVELOPMENT_TEAM` remains unset until an Apple Developer team is assigned.

## Integrated Scope

- Feedback stream integrated before this line: `feedback 14건 병렬 스트림 통합` folded sheet/composer/calendar feedback into the current design direction.
- Phase 1 complete: R26-R30 delivered the Unfading token reset, custom 3-tab shell, rebuilt bottom sheet, home chrome, and overlay stack.
- Phase 2 complete: R31-R35 delivered the rebuilt composer, Sprint 28 memory detail, calendar dial/day detail, rewind stories, and settings-driven group hub.
- Phase 3 complete: R36-R50 delivered ship assets, local StoreKit paywall, launchability/TestFlight helper scripts, real-data wiring, StoreKit sync stub, native Sign in with Apple client flow, realtime/offline handling, marker/detail stabilization, map themes, search, export, and the Phase 3 final documentation pass.
- Phase 4 complete: R51-R60 delivered performance hardening, radius-based map clustering, WidgetKit, Share Extension, Universal Links/custom deep links, Siri Shortcuts/App Intents expansion, background refresh processing, Korean/English localization, VoiceOver/Reduce Motion hardening, and the final documentation/evidence consolidation.

## Phase Checklist

### Phase 1 — R26-R30

- [x] Design tokens and bundled fonts aligned to Unfading visual system
- [x] Custom 3-tab shell and FAB shipped
- [x] Bottom sheet rebuilt and integrated
- [x] Home chrome coordinate/z-index polish landed
- [x] Group picker and category editor overlays integrated

### Phase 2 — R31-R35

- [x] Composer rebuilt around new flow and state model
- [x] Memory detail redesigned per Sprint 28
- [x] Calendar dial, plan card, and alert surfaces integrated
- [x] Rewind stories flow shipped
- [x] Settings-driven group hub flow integrated

### Phase 3 — R36-R50

- [x] Curated sheet/archive surfaces integrated
- [x] Marker selection and filtered detail entry stabilized
- [x] Real Supabase data wiring connected across map/calendar/detail
- [x] Accessibility and Dynamic Type pass landed
- [x] App icon, launch assets, and privacy manifest added
- [x] Local StoreKit paywall and subscription state shipped
- [x] Launchability/TestFlight helper scripts added
- [x] Photo UX, Sign in with Apple client, realtime, offline queue, map themes, search, export integrated
- [x] Phase 3 final docs/evidence recorded

### Phase 4 — R51-R60

- [x] Performance audit and image caching/body recompute reduction landed
- [x] Radius-based map clustering integrated
- [x] WidgetKit extension added with Today Memory snapshot strategy
- [x] Share Extension added for Photos.app handoff into composer
- [x] Universal Links + custom scheme routing integrated
- [x] Siri Shortcuts/App Intents expansion landed
- [x] Background refresh/rewind processing wired
- [x] Korean/English localization assets introduced
- [x] VoiceOver and Reduce Motion hardening integrated
- [x] R60 final docs/evidence and regression rerun recorded

## Status Table

| Area | Status | Notes |
|---|---|---|
| Design shell + core flows | CHECK | R26-R35 shell, sheet, overlays, composer, detail, calendar, rewind, and group surfaces remain integrated. |
| Data/account hardening | CHECK | R36-R50 real-data wiring, StoreKit sync stub, native Sign in with Apple client, realtime/offline, search, themes, and export remain present. |
| Performance + cluster surface | CHECK | R51-R52 performance cleanup and radius-based clustering are in the current app line. |
| WidgetKit | CHECK | Widget target is present; current widget data remains bundle-local/sample until App Group snapshot handoff is completed. |
| Share Extension | CHECK | Share extension target is present; real file-container handoff remains partially deferred to App Group setup. |
| Deep links + App Intents + background refresh | CHECK | R55-R57 routing, shortcuts, and BGTaskScheduler wiring are integrated in-app. |
| Localization + accessibility hardening | CHECK | R58-R59 added `xcstrings` localization and VoiceOver/Reduce Motion conformance work. |
| Archive helper | CHECK | `workspace/ios/scripts/archive.sh` passed `bash -n` on 2026-04-24. |
| Export options plist | CHECK | `workspace/ios/scripts/export-options.plist` passed `plutil -lint` on 2026-04-24. |
| Source test inventory | CHECK | Current source inventory is `217` unit + `29` UITest = `246` test methods. |
| Latest historical green baseline | CHECK | `context_harness/reports/round_data_export_r1/evidence/xcresult_summary.json` remains the latest full green baseline: `229` total / `215` passed / `14` skipped / `0` failed. |
| Requested final regression rerun | BLOCKED | The 2026-04-24 R60 rerun created `.deriveddata/r60/Test-R60.xcresult` but stopped before test execution with `xcodebuild` exit `74`. |
| Signed archive / TestFlight submission | DEFER | External operator setup is still required before a real signed upload can be completed. |

## Final Test Snapshot

- Current source inventory: `217` unit tests + `29` UITests = `246` test methods.
- Latest historical green simulator baseline: `229` total / `215` passed / `14` skipped / `0` failed (`round_data_export_r1` evidence).
- Current R60 rerun in this sandbox: `0` executed, `.xcresult` status `failedToStart`, `xcodebuild` exit `74`.

## Known Environment Blockers For R60 Rerun

- `CoreSimulatorService connection became invalid`
- `Unable to discover any Simulator runtimes`
- SwiftPM package resolution failed because GitHub host lookup was unavailable
- multiple `fatal: unable to access 'https://github.com/...': Could not resolve host: github.com`

## Deferred Operator Actions

| Item | Owner | Reason |
|---|---|---|
| Apple Developer team ID registration | Operator / account owner | `DEVELOPMENT_TEAM` is unset, so signed archive/export cannot complete. |
| App Store Connect app + subscription product registration | Operator / account owner | `com.jeonsihyeon.memorymap.premium.monthly` and `.yearly` must exist before production billing review. |
| Entitlement capability verification in signing environment | Operator / account owner | Sign in with Apple, Background fetch, Associated Domains, and Push Notifications must be confirmed against the provisioning profile. |
| AASA deployment to `https://unfading.app/.well-known/apple-app-site-association` | Operator / infra owner | Universal Links cannot be validated end-to-end until the file is live. |
| Supabase dashboard hardening | Operator / backend owner | HIBP leaked-password protection, email confirm, and Apple provider Services ID remain external dashboard tasks. |
| Privacy manifest final review | Operator / release owner | Final pre-submit audit is still required. |
| App Privacy Data Collection disclosure in App Store Connect | Operator / release owner | Privacy answers are not an in-repo artifact. |
| TestFlight tester invitation pass | Operator / release owner | External upload + tester management step. |
| App Store listing metadata | Operator / release owner | Screenshots, description, category, and age rating remain pending. |
| Real-device signed archive/export/upload | Operator / release owner | Requires provisioned signing environment and App Store Connect access. |

## Evidence

- Phase 4 final evidence: `context_harness/reports/phase4_final/evidence/`
- R60 test log: `context_harness/reports/phase4_final/evidence/xcodebuild_test_r60.log`
- R60 summary: `context_harness/reports/phase4_final/evidence/xcresult_summary.json`
- Archive helper: `workspace/ios/scripts/archive.sh`
- Export plist: `workspace/ios/scripts/export-options.plist`
