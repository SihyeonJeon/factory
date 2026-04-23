# r14 spec base 213833d
## Deliverables
1. workspace/ios/UITests/UnfadingUITests.swift — XCUITest target: testMapTabScreenshot, testCalendarTabScreenshot, testRewindTabScreenshot, testSettingsTabScreenshot, testComposerOpenScreenshot, testGroupHubScreenshot, testMemoryDetailScreenshot; use XCUIScreenshotAttach to collect. Each test seeds onboarding=true via launchArguments and navigates via XCUIElementQuery.
2. workspace/ios/project.yml — add UnfadingUITests target (type: bundle.ui-testing, sources: UITests, dependencies: MemoryMap)
3. docs/product-specs/launchability-review-2026.md — launch readiness checklist: Info.plist privacy strings complete, LaunchScreen configured, AppIcon present or placeholder, version 1.0.0 / build 1, StoreKit integration status (deferred), provisioning notes, TestFlight prep notes, known limitations vs deepsight prototype, monetization rollout plan
4. Tests ≥ 97 (90 + ≥ 7 UI tests)

## Acceptance
- UITest target builds and passes
- Screenshots for all 5 tabs + composer + detail in reports/round_launchability_r1/evidence/screenshots/
- Launchability doc exists with specific item checkboxes
