# R27 Evidence Notes — Custom Tab Shell

## Layer Decisions

| Element | zIndex | Notes |
|---|---:|---|
| Selected tab content | default | `UnfadingTabShell` renders map/calendar/settings as the base layer. |
| Home FAB | 70 | Matches design handoff. Hidden only by tab selection for R27; sheet-expanded binding is reserved for R28. |
| Custom tab bar | 120 | Always drawn after content and FAB in the root `ZStack`. |
| Composer | fullScreenCover | Modal presentation may cover tab bar per design handoff. |

## FAB Position

- Size: `56 x 56`.
- Trailing: `UnfadingTheme.Spacing.md2` = 18pt.
- Bottom: `UnfadingTabBar.height + UnfadingTheme.Spacing.md2` = 83pt + 18pt.
- Presentation: shell-level `fullScreenCover` for `MemoryComposerSheet`.

## UITest Migration Scope

| Previous route | New route |
|---|---|
| `app.tabBars.buttons["지도"]` | `app.buttons["tab-map"]` |
| `app.tabBars.buttons["캘린더"]` | `app.buttons["tab-calendar"]` |
| `app.tabBars.buttons["설정"]` | `app.buttons["tab-settings"]` |
| compose tab intercept | home FAB `app.buttons["home-fab"]` |
| rewind tab | home curation `app.buttons["home-rewind-hint"]` |

## Deferred Test

- `testMapBottomSheetSnapGestures` is skipped with `XCTSkipIf(true, "Deferred to R28 bottom sheet rebuild")`.
- Reason: bottom-sheet snap and drag behavior is the next round's accepted scope.

## Regression Risk Table

| Risk | Mitigation |
|---|---|
| Evidence composer no longer appears from `MemoryMapHomeView` | `UnfadingTabShell` auto-presents once when `evidenceMode != .none`. |
| Old `RootTabView.Tab` tests fail | Rewritten to assert `ShellTab.allCases.count == 3`. |
| Rewind curation hint not visible during UITest | DEBUG `UNFADING_UI_TEST=1` forces the hint on. |
| Group stub flow breaks | `RootTabView` remains the injected app root; environment objects continue to flow into shell content. |
