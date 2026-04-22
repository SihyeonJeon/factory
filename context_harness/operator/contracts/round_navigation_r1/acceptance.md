# round_navigation_r1 Acceptance Criteria

Every criterion must be mechanically checkable during evidence capture.

## Root Navigation

`RootTabView.swift` must define or expose five tab cases in order: map, calendar, compose, rewind, settings.

Suggested checks:

```bash
rg -n 'case map|case calendar|case compose|case rewind|case settings' workspace/ios/App/RootTabView.swift
rg -n 'MemoryMapHomeView|CalendarView|MemoryComposerSheet|RewindFeedView|SettingsView' workspace/ios/App/RootTabView.swift
```

The top-level root must not include `GroupHubView` as a tab target:

```bash
rg -n 'tabItem|GroupHubView|groups' workspace/ios/App/RootTabView.swift
```

Expected state: `GroupHubView` is not a top-level `tabItem` target.

## Korean Tab Labels

Tab labels must come from `UnfadingLocalized.Tab`:

```bash
rg -n 'UnfadingLocalized\.Tab\.(map|calendar|compose|rewind|settings)' workspace/ios/App/RootTabView.swift
rg -n 'static let (map|calendar|compose|rewind|settings)' workspace/ios/Shared/UnfadingLocalized.swift
```

Expected Korean values:

- `지도`
- `캘린더`
- `추억`
- `리와인드`
- `설정`

## Calendar Stub

`CalendarView.swift` must exist:

```bash
test -f workspace/ios/Features/Calendar/CalendarView.swift
```

It must contain a Korean placeholder:

```bash
rg -n '달력 화면 준비 중|UnfadingLocalized\.(Calendar|Placeholder)' workspace/ios/Features/Calendar/CalendarView.swift workspace/ios/Shared/UnfadingLocalized.swift
```

## Settings Stub

`SettingsView.swift` must exist:

```bash
test -f workspace/ios/Features/Settings/SettingsView.swift
```

It must contain a Korean placeholder and a `그룹 관리` row:

```bash
rg -n '설정|준비 중|그룹 관리|GroupHubView' workspace/ios/Features/Settings/SettingsView.swift workspace/ios/Shared/UnfadingLocalized.swift
```

## Compose Presentation

Selecting the compose tab must present `MemoryComposerSheet` with a `fullScreenCover` pattern and restore the previous selected tab on dismiss.

Suggested checks:

```bash
rg -n 'fullScreenCover|MemoryComposerSheet|previousTab|selectedTab|compose' workspace/ios/App/RootTabView.swift
```

## Tests

The project test suite must succeed:

```bash
cd workspace/ios
xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=<available simulator>'
```

Required result:

- exit code `0`
- total tests at least `33`

## Swift Lint

No forbidden inline colors in touched files:

```bash
rg -n 'Color\.(accentColor|white|black)\b|Color\(red:' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Calendar/CalendarView.swift \
  workspace/ios/Features/Settings/SettingsView.swift
```

Expected result: no matches.

No user-facing English literal strings in touched views:

```bash
rg -n 'Text\("[A-Za-z][^"]*"\)|Label\("[A-Za-z][^"]*"|accessibility(Label|Hint)\("[A-Za-z][^"]*"\)|navigationTitle\("[A-Za-z][^"]*"\)' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Calendar/CalendarView.swift \
  workspace/ios/Features/Settings/SettingsView.swift
```

Expected result: no matches. `systemImage` values, identifiers, enum cases, and test names are not user-facing strings for this criterion.

## Runtime Screenshots

Evidence must include screenshots for each tab:

```bash
test -f context_harness/reports/round_navigation_r1/screenshots/tab_map.png
test -f context_harness/reports/round_navigation_r1/screenshots/tab_calendar.png
test -f context_harness/reports/round_navigation_r1/screenshots/tab_compose.png
test -f context_harness/reports/round_navigation_r1/screenshots/tab_rewind.png
test -f context_harness/reports/round_navigation_r1/screenshots/tab_settings.png
```

Each screenshot path and SHA-256 hash must be recorded in the evidence report.

## Evidence And Verdict

Required artifacts:

- `context_harness/reports/round_navigation_r1/evidence/contract_capture.md`
- `context_harness/reports/round_navigation_r1/verdict.md`
- `context_harness/reports/round_navigation_r1/evidence/xcode_test.log`

Gate evidence must include test log, evidence report, verdict, and screenshot artifact hashes.
