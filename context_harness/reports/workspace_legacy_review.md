# Workspace Legacy Review

## Summary

The workspace has been consolidated around a single production path:

- the native SwiftUI iOS app under `workspace/ios/`

The previous Expo / React Native scaffold at the workspace root has been retired and removed.

## Keep

- `workspace/ios/`
  - Current native iOS source of truth.
  - Contains the active Xcode project and SwiftUI app skeleton.
- `workspace/ios/MemoryMap.xcodeproj`
  - Active native project.
- `workspace/ios/project.yml`
  - XcodeGen source for regenerating the project safely.
- `workspace/ios/App/`
  - Active application entrypoint and root tabs.
- `workspace/ios/Features/`
  - Active feature slices for map, rewind, and groups.
- `workspace/ios/Shared/`
  - Shared sample models for current native app skeleton.
- `workspace/ios/Tests/`
  - Active unit-test target.

## Removed

- `workspace/App.tsx`
- `workspace/index.ts`
- `workspace/app.json`
- `workspace/babel.config.js`
- `workspace/tailwind.config.js`
- `workspace/tsconfig.json`
- `workspace/package.json`
- `workspace/package-lock.json`
- `workspace/assets/`
- `workspace/.claude.json`
- `workspace/node_modules/`

These belonged to the retired Expo scaffold and were removed to eliminate dual-source-of-truth risk.

## Current Recommendation

- Production path: `workspace/ios/`
- Evaluation path: native Xcode evidence first
- Do not reintroduce a second app runtime at the workspace root unless it is explicitly scoped as a disposable harness
