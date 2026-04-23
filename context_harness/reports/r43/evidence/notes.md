# R43 Notes

- Implemented native Sign in with Apple wiring in iOS app code (`AppleSignInCoordinator`, `AuthStore`, `AuthLandingView`).
- Ran `xcodegen generate` successfully in `workspace/ios`.
- Ran `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r43`; build did not reach tests because this sandbox cannot access `CoreSimulatorService` and cannot fetch Swift package dependencies from GitHub.
- Ran `xcodebuild build-for-testing ... -derivedDataPath .deriveddata/r43 -clonedSourcePackagesDirPath <existing SourcePackages>`; package resolution still failed because SwiftPM diagnostics/cache writes to `~/Library/Caches/org.swift.swiftpm` are blocked in this sandbox.
- Operator action required in Supabase dashboard: `Auth -> Providers -> Apple` enable provider and configure Apple `Services ID` / related credentials. Codex did not modify dashboard settings.
- Real Apple Sign In flow requires a physical device or properly entitled simulator environment for runtime validation.
