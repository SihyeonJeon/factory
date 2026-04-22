# round_foundation_reset_r1 Acceptance Criteria

Each criterion below must be mechanically checked during evidence capture.

## Reusable Modules

### Files Exist

```bash
test -f workspace/ios/Shared/UnfadingTheme.swift
test -f workspace/ios/Shared/UnfadingLocalized.swift
test -f workspace/ios/Shared/UnfadingButtonStyle.swift
test -f workspace/ios/Shared/UnfadingCardBackground.swift
```

### Production And Test Usage

Each module must be referenced at least once by production Swift and at least once by tests.

```bash
rg -n 'UnfadingTheme' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingTheme' workspace/ios/Tests -g '*.swift'
rg -n 'UnfadingLocalized' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingLocalized' workspace/ios/Tests -g '*.swift'
rg -n 'UnfadingPrimaryButtonStyle|unfadingPrimaryButton|\.unfadingPrimary' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingPrimaryButtonStyle|unfadingPrimaryButton|\.unfadingPrimary' workspace/ios/Tests -g '*.swift'
rg -n 'UnfadingCardBackground|unfadingCardBackground|\.unfadingCard' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingCardBackground|unfadingCardBackground|\.unfadingCard' workspace/ios/Tests -g '*.swift'
```

Each command must return at least one match.

## Swift Color Lint

No forbidden color calls may remain outside `UnfadingTheme.swift` in app source:

```bash
rg -n 'Color\.(accentColor|white|black)\b|Color\(red:' \
  workspace/ios/App workspace/ios/Features workspace/ios/Shared \
  -g '*.swift' -g '!UnfadingTheme.swift'
```

Expected result: no matches.

## Korean User-Facing Strings

No user-facing English string literals may remain in touched view files:

```bash
rg -n 'Text\("[A-Za-z][^"]*"\)|Label\("[A-Za-z][^"]*"|accessibility(Label|Hint)\("[A-Za-z][^"]*"\)' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Home/MemoryMapHomeView.swift \
  workspace/ios/Features/Home/MemoryComposerSheet.swift \
  workspace/ios/Features/Home/MemorySummaryCard.swift
```

Expected result: no matches. `systemImage` values, identifiers, enum cases, and test names are not user-facing strings for this criterion.

## Token Values

`UnfadingTheme` must expose stable values from `docs/design-docs/deepsight_tokens.md`:

- `UnfadingTheme.Color.coral` represents `#F5998C`
- `UnfadingTheme.Radius.card == 20`
- `UnfadingTheme.Radius.button == 16`
- `UnfadingTheme.Radius.chip == 12`
- `UnfadingTheme.Radius.compact == 8`
- `UnfadingTheme.Sheet.collapsed == 0.22`
- `UnfadingTheme.Sheet.default == 0.52`
- `UnfadingTheme.Sheet.expanded == 0.88`

Evidence may come from `UnfadingThemeTests.swift` and/or direct source grep.

## Tests

Run the project test suite and capture log + SHA:

```bash
cd workspace/ios
xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=<available simulator>'
```

Required result:

- exit code `0`
- total tests at least `18`
- `workspace/ios/Tests/UnfadingThemeTests.swift` exists

## Documentation Reconciliation

`SESSION_RESUME.md` must contain an active truthful current-state section:

```bash
rg -n 'Reality Baseline|12 Swift|10 tests|3 tabs|No UnfadingTheme|No Korean' context_harness/SESSION_RESUME.md
```

`SESSION_RESUME.md` must not present the old Sprint 51 / 140-test narrative as active current state:

```bash
rg -n 'Sprint 51|140' context_harness/SESSION_RESUME.md
```

Any matches must be inside a clearly labeled archive pointer or historical warning, not current-state text.

The pre-v5 archive must exist:

```bash
test -f docs/exec-plans/sprint-history-pre-v5.md
rg -n 'pre-v5|unverified|archive|Sprint 51|140' docs/exec-plans/sprint-history-pre-v5.md
```

Forward-looking convention notes must exist:

```bash
rg -n 'UnfadingTheme|foundation reset|post-reset' docs/references/coding-conventions.md SKILLS.md
```

## Git Tracking

Swift source changes must be visible to git; generated Xcode/build artifacts must remain ignored.

```bash
git status --short workspace/ios/App workspace/ios/Features workspace/ios/Shared workspace/ios/Tests workspace/ios/project.yml
rg -n 'workspace|xcodeproj|DerivedData|build' .gitignore
```

Expected state:

- source/test/project files under `workspace/ios/` appear in git status when changed
- `workspace/ios/*.xcodeproj` and build products remain ignored

## Evidence And Verdict

Required artifacts:

- `context_harness/reports/round_foundation_reset_r1/evidence/contract_capture.md`
- `context_harness/reports/round_foundation_reset_r1/verdict.md`

Gate evidence must include:

- test log path and SHA
- evidence report path and SHA
- verdict path and SHA
- metrics/process evidence required by the active checker

## Non-Regression Boundaries

No new screen implementation is required in this round. Calendar, Settings, Memory Detail, archive, and navigation redesign remain out of scope.
