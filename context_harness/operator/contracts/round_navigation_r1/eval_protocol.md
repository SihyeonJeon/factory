# round_navigation_r1 Evaluation Protocol

## Purpose

This protocol captures factual evidence for the five-tab navigation foundation round. Evidence must verify root tab structure, Korean tab labels, Calendar and Settings stubs, compose-tab presentation behavior, tests, Swift lint, and runtime screenshots for all five tab states.

Evidence capture is factual only. Do not use verdict words such as `PASS`, `BLOCKER`, or `ADVISORY` in evidence.

## Evidence Output

Write factual evidence to:

`context_harness/reports/round_navigation_r1/evidence/contract_capture.md`

Also capture:

- Test log: `context_harness/reports/round_navigation_r1/evidence/xcode_test.log`
- Screenshots under: `context_harness/reports/round_navigation_r1/screenshots/`

## Static Source Checks

Capture root tab structure:

```bash
rg -n 'case map|case calendar|case compose|case rewind|case settings' workspace/ios/App/RootTabView.swift
rg -n 'MemoryMapHomeView|CalendarView|MemoryComposerSheet|RewindFeedView|SettingsView|GroupHubView' workspace/ios/App/RootTabView.swift
```

Capture localization additions:

```bash
rg -n 'UnfadingLocalized\.Tab\.(map|calendar|compose|rewind|settings)' workspace/ios/App/RootTabView.swift
rg -n 'static let (map|calendar|compose|rewind|settings)' workspace/ios/Shared/UnfadingLocalized.swift
rg -n '달력 화면 준비 중|그룹 관리|설정' workspace/ios/Shared/UnfadingLocalized.swift workspace/ios/Features/Calendar/CalendarView.swift workspace/ios/Features/Settings/SettingsView.swift
```

Capture compose presentation pattern:

```bash
rg -n 'fullScreenCover|MemoryComposerSheet|previousTab|selectedTab|compose' workspace/ios/App/RootTabView.swift
```

## Swift Lint Checks

Forbidden inline color patterns in touched files:

```bash
rg -n 'Color\.(accentColor|white|black)\b|Color\(red:' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Calendar/CalendarView.swift \
  workspace/ios/Features/Settings/SettingsView.swift
```

Expected evidence result: no matches.

Forbidden user-facing English literals in touched views:

```bash
rg -n 'Text\("[A-Za-z][^"]*"\)|Label\("[A-Za-z][^"]*"|accessibility(Label|Hint)\("[A-Za-z][^"]*"\)|navigationTitle\("[A-Za-z][^"]*"\)' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Calendar/CalendarView.swift \
  workspace/ios/Features/Settings/SettingsView.swift
```

Expected evidence result: no matches.

## Test Evidence

Run the project test suite and capture log + SHA:

```bash
cd workspace/ios
xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=<available simulator>' | tee ../../context_harness/reports/round_navigation_r1/evidence/xcode_test.log
```

Then capture:

```bash
shasum -a 256 context_harness/reports/round_navigation_r1/evidence/xcode_test.log
```

Evidence must record:

- exact command
- simulator destination
- exit code
- test count
- log path and SHA-256

## Runtime Screenshot Capture

Build and install the app on a simulator. Use the same simulator family as the test run where practical.

Suggested command sequence:

```bash
mkdir -p context_harness/reports/round_navigation_r1/screenshots
xcrun simctl boot "iPhone 17" || true
xcodebuild -project workspace/ios/MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' build
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -path '*Build/Products/Debug-iphonesimulator/MemoryMap.app' -type d | head -n 1)
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted <bundle-id>
```

For each tab, navigate to the tab state and capture:

```bash
xcrun simctl io booted screenshot context_harness/reports/round_navigation_r1/screenshots/tab_map.png
xcrun simctl io booted screenshot context_harness/reports/round_navigation_r1/screenshots/tab_calendar.png
xcrun simctl io booted screenshot context_harness/reports/round_navigation_r1/screenshots/tab_compose.png
xcrun simctl io booted screenshot context_harness/reports/round_navigation_r1/screenshots/tab_rewind.png
xcrun simctl io booted screenshot context_harness/reports/round_navigation_r1/screenshots/tab_settings.png
```

Navigation between tabs may be performed by a small XCUITest helper, accessibility-driven UI automation, or documented coordinate taps. The evidence report must state which method was used. The compose screenshot must show the full-screen composer presentation.

Capture screenshot hashes:

```bash
shasum -a 256 context_harness/reports/round_navigation_r1/screenshots/tab_*.png
```

## Factual Language Rule

The evidence report records observed files, command results, hashes, screenshots, and grep output only. Codex writes verdict classification separately in `context_harness/reports/round_navigation_r1/verdict.md`.
