# Launchability Review 2026

Round: `round_launchability_r1`
Date: 2026-04-23
Primary locale: Korean (`ko_KR`)

## Info.plist Privacy Strings

- [x] `NSLocationWhenInUseUsageDescription` is present for nearby memory pins and place-based rewind moments.
- [x] `NSLocationAlwaysAndWhenInUseUsageDescription` is present for revisit-triggered rewind moments.
- [x] `NSPhotoLibraryUsageDescription` is present for attaching photos to group memories.
- [x] `NSPhotoLibraryAddUsageDescription` is present for saving shared memory photos.
- [x] `UNUserNotificationCenterUsageDescription` is present for rewind reminders and group updates.

## LaunchScreen

- [x] `UILaunchScreen` is configured in `workspace/ios/project.yml`.
- [ ] Current `UIColorName` is empty. This is acceptable for a simulator launch smoke test, but before App Store submission the app should either set an explicit launch-screen color asset that matches the app background or use an AppIcon-driven launch asset to avoid a generic blank transition.

## AppIcon

- [ ] AppIcon assets are currently missing from the XcodeGen project. A full App Store icon set is required before release.

## Version And Build

- [x] `MARKETING_VERSION` is set to `1.0.0` in `workspace/ios/project.yml`.
- [x] `CURRENT_PROJECT_VERSION` is set to `1` in `workspace/ios/project.yml`.
- [ ] TestFlight automation should bump `CURRENT_PROJECT_VERSION` on every uploaded build.

## StoreKit 2 Integration

- [x] Monetization remains deferred per the R11 `PremiumPreviewSheet` placeholder path.
- [ ] Add a local StoreKit configuration file with product IDs for monthly and annual couple/group plans.
- [ ] Implement StoreKit 2 product loading, purchase, restore, transaction listener, and entitlement cache.
- [ ] Add server-side validation through App Store Server API before granting high-cost storage or AI entitlements.
- [ ] Add billing retry, grace period, refund, and subscription-management flows.

## Privacy And Tracking Labels

- [x] No third-party SDKs are currently integrated.
- [ ] App Privacy declaration should cover location, photos, user content, identifiers/account data if added, diagnostics if enabled, and notification usage.
- [x] Tracking label should remain minimal unless advertising, cross-app tracking, or third-party analytics are introduced.

## TestFlight Prep

- [ ] Configure a valid Apple development team and signing style.
- [ ] Create provisioning profiles for `MemoryMap` and `UnfadingUITests`.
- [ ] Add a build-number bump script for `CURRENT_PROJECT_VERSION`.
- [ ] Add export options plist for archive export.
- [ ] Capture a clean `xcodebuild archive` log before external TestFlight distribution.

## Localization Base

- [x] Korean is the primary launch language and the current UI copy baseline.
- [ ] Add explicit `ko_KR` and English secondary localization resources before public launch.
- [ ] Migrate hard-coded Korean strings toward string catalog coverage as the English surface is added.

## Monetization Rollout Plan

- [x] Closed beta: free-only app, no purchase flow, validate memory capture, map browsing, calendar, Rewind, and group hub.
- [ ] Open beta: introduce premium previews, transparent plan copy, storage/memory limit messaging, and export preview moments.
- [ ] Version 1.0: keep core viewing and existing memory access free; ship App Store privacy, terms, screenshots, and Korean/English listing copy.
- [ ] In-app purchase enablement: launch StoreKit 2 subscriptions after product-market fit signals, starting with KRW 4,900/month or KRW 49,000/year couple/small-group premium and KRW 8,900/month or KRW 89,000/year group/family premium.

## Known Limitations Vs Deepsight

- [ ] Real Supabase backend integration is not yet present in the Swift app.
- [ ] True cloud sync, conflict handling, auth, and group membership persistence are not complete.
- [ ] Advanced map styling has not fully reached the deepsight token target.
- [ ] Production media upload, quota enforcement, AI Rewind generation, and export jobs are still deferred.
- [ ] AppIcon, full launch branding, and App Store screenshot set remain release blockers.

## Pre-Submission Checklist

- [ ] App Store screenshots for required device sizes, including map, calendar, Rewind, settings, composer, group hub, and memory detail.
- [ ] Review notes explaining location/photo/notification permission prompts and the current beta scope.
- [ ] Age rating target: 12+ due to user-generated content, location sharing context, and group interactions.
- [ ] Korean and English app descriptions.
- [ ] Korean and English keywords.
- [ ] Privacy policy URL and support URL.
- [ ] Terms/subscription copy before StoreKit enablement.
