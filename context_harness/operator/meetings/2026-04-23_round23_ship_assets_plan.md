---
round: round_ship_assets_r1
stage: planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r23-assets
contract_hash: none
---

## Context

- R23 addresses AppIcon wiring, launch screen asset wiring, and Apple privacy manifest readiness.
- The 1024px app icon asset and base asset catalog files already exist under `workspace/ios/App/Assets.xcassets`.
- `MemoryMap` is generated from `workspace/ios/project.yml`; generated Info.plist properties must remain aligned with `App/Info.plist`.
- This is a bounded ship-readiness round, not a brand redesign round.

## Proposal

- Add the asset catalog and privacy manifest as `MemoryMap` resources.
- Set `ASSETCATALOG_COMPILER_APPICON_NAME` to `AppIcon`.
- Use plist-native `UILaunchScreen` with `AccentColor`, `LaunchLogo`, and safe-area-respecting image placement.
- Generate a temporary `LaunchLogo.imageset/launch_logo.png` from the existing 1024px icon.
- Add `PrivacyInfo.xcprivacy` with the currently declared collected data and required-reason API categories.

## Questions

- Should the temporary launch logo ship if no final wordmark arrives before submission?

## Counter / Review

- Risk: reusing the full app icon as launch logo can look less polished than a transparent wordmark and should be marked temporary.
- Risk: privacy manifest declarations may need another review once cloud sync, analytics, purchase SDKs, or auth storage behavior changes.

## Convergence

- Proceed with the placeholder asset because it unblocks project generation and launch screen validation.
- Record final icon, wordmark, and dark-mode launch screen polish as deferred items.

## Decision

R23 will ship the project wiring, placeholder launch logo, and privacy manifest now. Final branded launch art remains deferred.

## Challenge Section

- Rejected alternative: leaving `UIColorName` empty and relying on default launch background. That leaves launch appearance underspecified and fails the stated asset-catalog strategy.
- Rejected alternative: adding a storyboard launch screen. The current plist launch screen is sufficient for this scope and avoids adding a new UI artifact.
