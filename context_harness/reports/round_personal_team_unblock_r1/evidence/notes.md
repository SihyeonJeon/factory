# round_personal_team_unblock_r1 Evidence Notes

## Acceptance 1
- Removed `com.apple.developer.applesignin`, `com.apple.developer.associated-domains`, and `com.apple.developer.background-modes` from `workspace/ios/App/MemoryMap.entitlements`.
- Confirmed `project.yml.targets.MemoryMap.info.properties.UIBackgroundModes` remains `fetch` and `processing`.
- `plutil -lint workspace/ios/App/MemoryMap.entitlements` passed.

## Acceptance 2
- Added explicit `DEVELOPMENT_TEAM: "$(DEVELOPMENT_TEAM)"` inheritance under `MemoryMap`, `UnfadingWidget`, and `UnfadingShareExtension` target `settings.base`.
- `xcodebuild -showBuildSettings DEVELOPMENT_TEAM=TEAM123456` resolved `DEVELOPMENT_TEAM = TEAM123456` for all three targets.
- User build command can inject one team id for all three targets:

```bash
cd workspace/ios && xcodegen generate
xcodebuild build -project MemoryMap.xcodeproj -scheme MemoryMap \
  -configuration Debug -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath .build/device -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic
```

## Acceptance 3
- Added `Shared/PaidDeveloperFeatures.swift` with `signInWithAppleAvailable = false` and `associatedDomainsAvailable = false`.
- Guarded the Sign in with Apple button and the following `또는` divider in `AuthLandingView`.
- Left `DeepLinkRouter` unchanged: `unfading://` custom scheme remains active, and `https://unfading.app/memory|event` parser behavior remains unit-test compatible.

## Build Verification
- `xcodegen generate` passed.
- Requested `xcodebuild test` produced `.deriveddata/r61/Test-R61.xcresult`, but status is `failedToStart`.
- Executed tests after this change: `0`, due to CoreSimulatorService connection invalid and package resolution failures for GitHub-hosted SwiftPM dependencies.

## Paid Transition Follow-up
- Proposed follow-up round headline: `paid_developer_features_r1` — restore paid entitlements, set paid feature toggles to true, configure AASA/Supabase Apple provider, and verify signed device build.
