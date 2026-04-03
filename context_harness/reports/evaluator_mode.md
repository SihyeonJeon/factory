# Evaluator Mode

The evaluator lane is intended to test the real app surface, not only static code.

## Current mode

- Native iOS is the primary evaluation path
- Xcode project discovery and native build evidence are the main release signals
- Claude review lane for code and regression checks
- HIG audit lane for iOS-native risk review
- Playwright-style Expo smoke is optional and skipped when the Expo scaffold is absent

## Limits

- Full simulator-driving artifact capture is still being strengthened.
- Expo web is no longer required once the native project becomes the sole source of truth.
