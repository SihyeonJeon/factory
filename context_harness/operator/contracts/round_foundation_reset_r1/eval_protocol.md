# round_foundation_reset_r1 Evaluation Protocol

## Purpose

This protocol captures factual evidence for the foundation reset implementation round. Evidence must show that reusable Swift modules exist, are used by production code and tests, Swift lint constraints are met, tests pass, and documentation now reflects the actual workspace state.

Evidence capture is factual only. Do not use verdict words such as `PASS`, `BLOCKER`, or `ADVISORY` in evidence.

## Evidence Output

Write factual evidence to:

`context_harness/reports/round_foundation_reset_r1/evidence/contract_capture.md`

Include command outputs or artifact paths with SHA-256 hashes where applicable.

## Reusable Module Verification

Required module paths:

- `workspace/ios/Shared/UnfadingTheme.swift`
- `workspace/ios/Shared/UnfadingLocalized.swift`
- `workspace/ios/Shared/UnfadingButtonStyle.swift`
- `workspace/ios/Shared/UnfadingCardBackground.swift`

Capture:

```bash
test -f workspace/ios/Shared/UnfadingTheme.swift
test -f workspace/ios/Shared/UnfadingLocalized.swift
test -f workspace/ios/Shared/UnfadingButtonStyle.swift
test -f workspace/ios/Shared/UnfadingCardBackground.swift
```

For each module, capture at least one production reference and at least one test reference:

```bash
rg -n 'UnfadingTheme' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingTheme' workspace/ios/Tests -g '*.swift'
rg -n 'UnfadingLocalized' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingLocalized' workspace/ios/Tests -g '*.swift'
rg -n 'UnfadingPrimaryButtonStyle|unfadingPrimaryButton|\\.unfadingPrimary' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingPrimaryButtonStyle|unfadingPrimaryButton|\\.unfadingPrimary' workspace/ios/Tests -g '*.swift'
rg -n 'UnfadingCardBackground|unfadingCardBackground|\\.unfadingCard' workspace/ios/App workspace/ios/Features workspace/ios/Shared -g '*.swift'
rg -n 'UnfadingCardBackground|unfadingCardBackground|\\.unfadingCard' workspace/ios/Tests -g '*.swift'
```

## Swift Lint Checks

Forbidden color patterns outside `UnfadingTheme.swift`:

```bash
rg -n 'Color\.(accentColor|white|black)\b|Color\(red:' \
  workspace/ios/App workspace/ios/Features workspace/ios/Shared \
  -g '*.swift' -g '!UnfadingTheme.swift'
```

Expected result: no matches.

Forbidden user-facing English strings in touched view files:

```bash
rg -n 'Text\("[A-Za-z][^"]*"\)|Label\("[A-Za-z][^"]*"|accessibility(Label|Hint)\("[A-Za-z][^"]*"\)' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Home/MemoryMapHomeView.swift \
  workspace/ios/Features/Home/MemoryComposerSheet.swift \
  workspace/ios/Features/Home/MemorySummaryCard.swift
```

Expected result: no matches after implementation. This grep intentionally targets user-facing SwiftUI strings, not identifiers, `systemImage` names, enum cases, or test names.

## Korean String Coverage

Capture every `Text`, `Label`, `accessibilityLabel`, and `accessibilityHint` occurrence in touched view files:

```bash
rg -n 'Text\(|Label\(|accessibilityLabel\(|accessibilityHint\(' \
  workspace/ios/App/RootTabView.swift \
  workspace/ios/Features/Home/MemoryMapHomeView.swift \
  workspace/ios/Features/Home/MemoryComposerSheet.swift \
  workspace/ios/Features/Home/MemorySummaryCard.swift
```

Evidence should state whether user-facing strings resolve to `UnfadingLocalized.*` or a dynamic non-user-facing value. Any implementation-time wording revision from `spec.md` must be listed with the final key and value.

## Token Value Verification

Capture token definitions or test evidence for:

- `UnfadingTheme.Color.coral` equals `#F5998C`
- `UnfadingTheme.Radius.card == 20`
- `UnfadingTheme.Radius.button == 16`
- `UnfadingTheme.Radius.chip == 12`
- `UnfadingTheme.Radius.compact == 8`
- `UnfadingTheme.Sheet.collapsed == 0.22`
- `UnfadingTheme.Sheet.default == 0.52`
- `UnfadingTheme.Sheet.expanded == 0.88`

## Test Evidence

Capture the exact test command, log path, log SHA-256, exit code, and test count.

Expected command shape:

```bash
cd workspace/ios
xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=<available simulator>' | tee ../../context_harness/reports/round_foundation_reset_r1/evidence/xcodebuild_test.log
```

If `xcodegen generate` is required before testing in the current workspace, capture that command and output separately.

Compute:

```bash
shasum -a 256 context_harness/reports/round_foundation_reset_r1/evidence/xcodebuild_test.log
```

Evidence must record test count and whether it is at least 18.

## Doc Reconciliation Verification

Capture:

```bash
rg -n 'Reality Baseline|12 Swift|10 tests|3 tabs|UnfadingTheme|Korean' context_harness/SESSION_RESUME.md
rg -n 'Sprint 51|140' context_harness/SESSION_RESUME.md
test -f docs/exec-plans/sprint-history-pre-v5.md
rg -n 'pre-v5|unverified|archive|Sprint 51|140' docs/exec-plans/sprint-history-pre-v5.md
rg -n 'UnfadingTheme|foundation reset|post-reset' docs/references/coding-conventions.md SKILLS.md
```

Evidence should distinguish current-state claims from archive labels.

## Git Tracking Verification

Capture `.gitignore` relevant lines and git status for workspace source files:

```bash
rg -n 'workspace|xcodeproj|DerivedData|build' .gitignore
git status --short workspace/ios/App workspace/ios/Features workspace/ios/Shared workspace/ios/Tests workspace/ios/project.yml
```

Evidence should state whether Swift source changes are visible to git while generated Xcode files remain ignored.

## Factual Language Rule

The evidence report must describe observed files, commands, hashes, line matches, and counts. Verdict classification is written only in `context_harness/reports/round_foundation_reset_r1/verdict.md`.
