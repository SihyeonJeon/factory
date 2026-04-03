# Native iOS Strategy

## Decision

- Primary target: native iOS app built with SwiftUI.
- Transitional target: keep Expo web only as a fast evaluation harness until native screens exist.
- Promotion rule: once `workspace/ios` contains a real Xcode project, evaluation must prefer Xcode runtime evidence over Expo-only evidence.

## Why

- The current product direction depends on iOS-native surfaces such as MapKit, location permissions, notifications, and App Store-grade interaction polish.
- Expo web is useful for rapid visual smoke tests, but it is not the final source of truth for HIG-sensitive native behavior.
- SwiftUI gives the strongest path to native layout behavior, accessibility, navigation, safe-area correctness, and App Store review confidence.

## Evaluation policy

- Before native project exists:
  - Use Playwright-style Expo web smoke tests.
  - Use screenshot review and HIG audits as provisional evidence only.
- After native project exists:
  - Require Xcode project discovery via `xcodebuild -list`.
  - Prefer simulator or preview capture as evaluation input.
  - Treat Expo-only evidence as supporting, not release-blocking, evidence.

## Delivery policy

- Product and planning may still use the existing Expo workspace for rapid prototyping artifacts.
- Architecture and implementation should converge on a SwiftUI-first file layout once native work starts.
- Native-only features should not be permanently modeled as web-first abstractions if that would distort iOS behavior.
