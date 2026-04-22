# Acceptance — round_map_redesign_r1

All criteria must pass before close.

## Files exist
- [ ] `workspace/ios/Shared/UnfadingBottomSheet.swift`
- [ ] `workspace/ios/Shared/UnfadingFilterChip.swift`
- [ ] `workspace/ios/Features/Home/MemorySelectionState.swift`
- [ ] `workspace/ios/Tests/UnfadingBottomSheetTests.swift`
- [ ] `workspace/ios/Tests/UnfadingFilterChipTests.swift`
- [ ] `workspace/ios/Tests/MemorySelectionStateTests.swift`

## Reusable module proof (Codex Q9)
- [ ] `UnfadingBottomSheet` referenced in ≥1 production + ≥1 test (grep `UnfadingBottomSheet`)
- [ ] `UnfadingFilterChip` referenced in ≥1 production + ≥1 test
- [ ] `MemorySelectionState` referenced in ≥1 production + ≥1 test

## Forbidden patterns
- [ ] `grep -rE "Color\\.(accentColor|white|black)|Color\\(red:" workspace/ios/App workspace/ios/Features workspace/ios/Shared | grep -v UnfadingTheme.swift` → empty
- [ ] English user-facing literals in `Text("...")` / `Label("...")` / `.accessibilityLabel("...")` / `.accessibilityHint("...")` / `.navigationTitle("...")` in touched view files → empty

## Build + test
- [ ] `xcodebuild ... test` exit 0
- [ ] test_count ≥ 44

## Runtime
- [ ] Screenshot of new Map default state captured
- [ ] Screenshot with pin selected (demonstrates selection state transition)

## Codex peer review
- [ ] Code review cycle recorded; any blocker fixed in-round; advisories recorded
