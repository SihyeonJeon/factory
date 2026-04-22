# round_navigation_r1 Specification

## Scope

This round replaces the current three-tab root with the Deepsight-aligned five-tab navigation foundation. It adds Calendar and Settings stubs, changes the compose entrypoint into a tab-triggered full-screen composer flow, and demotes Group Hub from top-level tab to a temporary Settings row.

## Source Inventory

| Source | SHA-256 |
|---|---|
| `workspace/ios/App/RootTabView.swift` | `sha256:9e67ea387f9cfbad7e4e94edec4fd9a625a85096b376fed5623acee6e61b1971` |
| `workspace/ios/Shared/UnfadingLocalized.swift` | `sha256:35ebf79e5a17dae43f450e2a82de161831aa7caddf9c29eab00a6663d07938d0` |
| `workspace/ios/Shared/UnfadingTheme.swift` | `sha256:6b7fb9e86ea4a5fe43e8d461c89262aeb548d936690f5be48b82d058e0501935` |

## Required Navigation Model

Root tab order must be:

| Order | Tab ID | Korean label | Target |
|---:|---|---|---|
| 1 | `map` | `지도` | `MemoryMapHomeView` |
| 2 | `calendar` | `캘린더` | `CalendarView` stub |
| 3 | `compose` | `추억` | Presents `MemoryComposerSheet` as `fullScreenCover` |
| 4 | `rewind` | `리와인드` | `RewindFeedView` |
| 5 | `settings` | `설정` | `SettingsView` stub |

Groups must not remain a top-level tab in this round. Group management is temporarily reachable from Settings via a visible Korean `그룹 관리` row. A later Map/Group Hub round may move it to a map group chip or sheet.

## Required Swift Changes

### `workspace/ios/App/RootTabView.swift`

Required behavior:

- Uses a five-tab `TabView` in the order `map`, `calendar`, `compose`, `rewind`, `settings`.
- Uses Korean tab labels from `UnfadingLocalized.Tab`.
- Uses `UnfadingTheme.Color.primary` for tab tint.
- Selecting the compose tab presents `MemoryComposerSheet` via `fullScreenCover`.
- Dismissing the composer restores the previously selected non-compose tab.
- The compose tab must not leave the root selection stuck on an empty compose view.
- Groups is removed as a top-level tab.

Recommended implementation shape:

- Introduce a local `RootTab` enum with cases `map`, `calendar`, `compose`, `rewind`, `settings`.
- Keep `previousTab` state for compose restore.
- Use a custom `Binding<RootTab>` or `onChange` pattern to intercept `.compose` selection.

### `workspace/ios/Features/Calendar/CalendarView.swift`

Required behavior:

- New file at exact path.
- Displays a Korean placeholder: `달력 화면 준비 중`.
- Uses `UnfadingTheme` and/or `UnfadingLocalized`.
- Has a navigation title or visible heading in Korean.
- Does not implement a month grid in this round.

### `workspace/ios/Features/Settings/SettingsView.swift`

Required behavior:

- New file at exact path.
- Displays a Korean placeholder for Settings.
- Contains a visible `그룹 관리` row.
- The `그룹 관리` row routes to, links to, or presents `GroupHubView`.
- Uses `UnfadingTheme` and/or `UnfadingLocalized`.
- Does not implement full settings functionality in this round.

### `workspace/ios/Shared/UnfadingLocalized.swift`

Required additions:

- `UnfadingLocalized.Tab.calendar = "캘린더"`
- `UnfadingLocalized.Tab.compose = "추억"`
- `UnfadingLocalized.Tab.settings = "설정"`
- Placeholder/navigation strings for Calendar and Settings stubs, including `달력 화면 준비 중` and `그룹 관리`.

## Tests

Add or update tests so total test count is at least 33.

Required test coverage:

- Five root tabs exist in order: map, calendar, compose, rewind, settings.
- Korean tab labels resolve from `UnfadingLocalized`.
- Compose tab selection triggers a full-screen composer presentation pattern and restores previous tab state.
- `CalendarView` placeholder strings are available and Korean.
- `SettingsView` placeholder and `그룹 관리` row strings are available and Korean.

## Runtime Evidence

Capture a runtime screenshot of each tab:

- `context_harness/reports/round_navigation_r1/screenshots/tab_map.png`
- `context_harness/reports/round_navigation_r1/screenshots/tab_calendar.png`
- `context_harness/reports/round_navigation_r1/screenshots/tab_compose.png`
- `context_harness/reports/round_navigation_r1/screenshots/tab_rewind.png`
- `context_harness/reports/round_navigation_r1/screenshots/tab_settings.png`

For compose, the screenshot should show the presented composer, not a blank underlying tab.

## Non-Goals

- No real Calendar month grid.
- No full Settings implementation.
- No Group Hub redesign.
- No Map top-left group chip or group sheet.
- No Memory Composer redesign beyond presentation wiring.
- No Rewind redesign.
- No Deepsight map shell redesign.
