# round_ship_assets_r1 Spec

## Scope

Ship the minimum App Store-facing asset metadata for the Unfading iOS app:

- Register the asset catalog with the `MemoryMap` target.
- Set `AppIcon` as the app icon catalog entry.
- Configure the plist launch screen to use `AccentColor` and `LaunchLogo`.
- Add a privacy manifest declaring the app data types and required-reason APIs currently implied by the local app surface.

## Implementation Requirements

- `workspace/ios/project.yml` must include `App/Assets.xcassets` and `App/PrivacyInfo.xcprivacy` as `MemoryMap` resources.
- `targets.MemoryMap.settings.base` must set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`.
- `UILaunchScreen` must include `UIColorName: AccentColor`, `UIImageName: LaunchLogo`, and `UIImageRespectsSafeAreaInsets: true` in both the project generation properties and checked-in plist.
- `LaunchLogo.imageset` must contain a placeholder `launch_logo.png` generated from the existing 1024px icon until final brand art is supplied.
- `PrivacyInfo.xcprivacy` must be valid plist XML and included in the app target resources.

## Non-Goals

- Final brand identity design.
- Dark-mode-specific launch art.
- StoreKit/App Store Connect configuration.
- Backend privacy policy drafting.

## Risks

- The launch logo placeholder reuses the full app icon composition, so it is acceptable only as a temporary ship-readiness asset.
- Privacy manifest declarations should be reviewed again when cloud sync, analytics, subscriptions, or third-party SDK behavior changes.
