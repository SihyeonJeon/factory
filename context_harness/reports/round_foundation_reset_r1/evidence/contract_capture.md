# Evidence — round_foundation_reset_r1 Contract Capture

**Author:** Claude Code Operator (STAGE_CONTRACT Stage 8 `runtime_capture` equivalent for implementation round)
**Capture protocol:** `context_harness/operator/contracts/round_foundation_reset_r1/eval_protocol.md`
**Scope:** factual observations only. Verdict authored separately by Codex Operator at `verdict.md`.

---

## Capture timestamp

2026-04-23T00:45Z

## Reusable modules — file hashes

| Module | Path | SHA-256 |
|---|---|---|
| Theme | `workspace/ios/Shared/UnfadingTheme.swift` | `sha256:6b7fb9e86ea4a5fe43e8d461c89262aeb548d936690f5be48b82d058e0501935` |
| Localized | `workspace/ios/Shared/UnfadingLocalized.swift` | `sha256:35ebf79e5a17dae43f450e2a82de161831aa7caddf9c29eab00a6663d07938d0` |
| ButtonStyle | `workspace/ios/Shared/UnfadingButtonStyle.swift` | `sha256:3cfd687b753e913676cbdf250cc2d147554d090a40400a8865dbaa43b924be1e` |
| CardBackground | `workspace/ios/Shared/UnfadingCardBackground.swift` | `sha256:a936b1b817b3646eb9f7956eaece7769c8dfa09e526acec489a18beaf852c725` |

## Refactored view files — file hashes

| Path | SHA-256 |
|---|---|
| `workspace/ios/App/RootTabView.swift` | `sha256:9e67ea387f9cfbad7e4e94edec4fd9a625a85096b376fed5623acee6e61b1971` |
| `workspace/ios/Features/Home/MemoryMapHomeView.swift` | `sha256:5a1218e558b960b9d962e3e73388aa28a8a38017dde6b59396e8b188d8e3afd0` |
| `workspace/ios/Features/Home/MemoryComposerSheet.swift` | `sha256:50d2ce359e06d4f50f3c16d6aee43459ad433e43c0d81344c45aa92f38f7a85c` |
| `workspace/ios/Features/Home/MemorySummaryCard.swift` | `sha256:d4f3d89bdb0a55f279c71e703d21932b1b7c407b4801668caa6c4cb3b3a28f93` |
| `workspace/ios/Features/Home/MemoryPinMarker.swift` | `sha256:2c8eb06786cb1f8471794db94e47e3ee026f17810354eaa064f1d6a38944f877` |
| `workspace/ios/Features/Rewind/RewindFeedView.swift` | `sha256:3607d95cf09adfa4e817b07dac3f3ae6bb908cbe7d892aa97165f4d7c08d037a` |
| `workspace/ios/Features/Rewind/RewindMomentCard.swift` | `sha256:1cd35123f6a8db68c2d0501bc34ad8ed0d36a2c0f670d480bdacfb93d470f9b9` |
| `workspace/ios/Features/Groups/GroupHubView.swift` | `sha256:2b09955549251bcada4aab5b11950063bdec60b672a6063747876051e3747ac9` |

## New test files — file hashes

| Path | SHA-256 |
|---|---|
| `workspace/ios/Tests/UnfadingThemeTests.swift` | `sha256:d2bc0cc628d548090bc80b61b0530d86d64a12ad9c1aa8c0de49526774bb7713` |
| `workspace/ios/Tests/UnfadingLocalizedTests.swift` | `sha256:466d5d733f46465f950fdf4e4d807bb2a0f1ec10d8b35629aeebb13b17baf5cf` |
| `workspace/ios/Tests/UnfadingComponentTests.swift` | `sha256:1c0f864b125297537f7a05bd3ec17b60b7ba617ba9b779834ff8ff3279814a37` |

## Doc reconciliation — file hashes

| Path | SHA-256 | Note |
|---|---|---|
| `context_harness/SESSION_RESUME.md` | `sha256:e6529f08b5e0f1ff4cbdc3dd16a904eb8814a844291b8e58051db205f708de22` | Rewritten to truthful Reality Baseline |
| `docs/exec-plans/sprint-history-pre-v5.md` | `sha256:4cf40e7dff0fad45388db4afc138fa456b7d3df0e591c83433ade2bec67165c7` | Unverified pre-v5 narrative archive |

## Test results

- Command: `xcodebuild -project workspace/ios/MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' test`
- Exit status: 0
- Log: `context_harness/reports/round_foundation_reset_r1/evidence/xcode_test.log` sha256 `ce4921e536c4fcbcaf618386605d0e9921873e4ccdb6aca19809a58ca2703238`
- Test count: 28 (baseline 10 + 18 new across `UnfadingThemeTests`, `UnfadingLocalizedTests`, `UnfadingComponentTests`)
- All tests passed; log end line: `** TEST SUCCEEDED **`

## Acceptance grep results

### Forbidden Color patterns (target: zero outside `UnfadingTheme.swift`)

Command (from repo root):
```
grep -rn -E "Color\\.(accentColor|white|black)|Color\\(red:" workspace/ios/App workspace/ios/Features workspace/ios/Shared | grep -v "UnfadingTheme.swift"
```

Result: empty (no matches).

### Reusable module usage proof (Codex R-round2 Q9: ≥1 production + ≥1 test reference each)

| Module | Production files referencing | Test files referencing |
|---|---:|---:|
| `UnfadingTheme` | 8 | 2 |
| `UnfadingLocalized` | 6 | 1 |
| `UnfadingPrimaryButtonStyle` (via `.unfadingPrimary` shorthand) | 2 (`MemoryMapHomeView.swift`, `MemoryComposerSheet.swift`) | 1 (`UnfadingComponentTests.swift`) |
| `unfadingCardBackground` modifier | 2 (`MemorySummaryCard.swift`, `RewindMomentCard.swift`) | 1 (`UnfadingComponentTests.swift`) |

All 4 modules satisfy the ≥1 production + ≥1 test threshold.

### English user-facing string literals in touched view files

Command (per view file):
```
grep -nE 'Text\("[A-Za-z]|Label\("[A-Za-z]|accessibilityLabel\("[A-Za-z]|accessibilityHint\("[A-Za-z]|\.navigationTitle\("[A-Za-z]'
```

Result: empty across all 8 touched view files (`RootTabView`, `MemoryMapHomeView`, `MemoryComposerSheet`, `MemorySummaryCard`, `MemoryPinMarker`, `RewindFeedView`, `RewindMomentCard`, `GroupHubView`).

Notes:
- `searchText.trimmingCharacters(...)` Label arguments in `ManualPlacePickerSheet` show raw user input; not a literal — passes.
- `SampleMemoryPin.title`, `RewindMoment.title`, `GroupPreview.name`, `MemoryDraftTag.title`, `PlaceSuggestion.title/subtitle` are MODEL data (not literal arguments in views). They are sample English strings carried through from `SampleModels.swift` / `LocationPermissionStore.swift`, which are outside this round's whitelist. `MemoryDraftTag` and `PlaceSuggestion` are routed through `UnfadingLocalized.draftTag(id:...)` / `UnfadingLocalized.placeSuggestion(id:...)` helpers at display sites; remaining English model strings (`SampleMemoryPin`, `RewindMoment`, `GroupPreview`) surface in views as variable references, not literal arguments, and acceptance targets only literals within touched view files. Full sample-data localization can be addressed in a future round that whitelists `SampleModels.swift`.

### UnfadingTheme token values (verified by unit tests)

- `UnfadingTheme.Color.coral` resolves to R=0xF5, G=0x99, B=0x8C → matches `deepsight_tokens.md` Coral `#F5998C`.
- `UnfadingTheme.Color.lavender` resolves to R=0xC2, G=0xB0, B=0xDE.
- `UnfadingTheme.Color.cream` resolves to R=0xFF, G=0xFA, B=0xF5.
- `UnfadingTheme.Color.primary` is channel-identical to `.coral`.
- `UnfadingTheme.Radius` covers {20, 16, 12, 8} exactly.
- `UnfadingTheme.Sheet` covers {0.22, 0.52, 0.88} exactly.
- `UnfadingTheme.Spacing` is monotonic xs→xxl.

Unit test evidence: `UnfadingThemeTests.swift` — 7 tests all passed.

### Korean localization coverage (verified by unit tests)

- `UnfadingLocalized.Tab.map`, `.rewind`, `.groups` are Korean non-empty.
- `UnfadingLocalized.Accessibility.*TabLabel` contain the matching Korean tab names.
- `UnfadingLocalized.Summary.sampleBody` contains Hangul syllables (verified by code point range check).
- `UnfadingLocalized.Composer.navTitle`/`.save`, `Common.cancel` match expected Korean.
- `UnfadingLocalized.draftTag(id:)` returns Korean for all 4 known ids; returns fallback for unknown id.
- `UnfadingLocalized.placeSuggestion(id:)` returns Korean title+subtitle for known ids.

Unit test evidence: `UnfadingLocalizedTests.swift` — 7 tests all passed.

### Reusable module compile + wire integration

- Standalone `xcodebuild build` succeeded after module creation (prior to refactors).
- After refactors, `xcodebuild test` succeeded with 28/28 tests passing.
- `xcodegen generate` ran twice (once after initial modules, once after adding new test files) to re-wire `MemoryMap.xcodeproj`.

### Doc reconciliation

- `SESSION_RESUME.md` now begins with truthful Reality Baseline section (Date 2026-04-23, 16 Swift files, 28 tests, 3 tabs, Korean labels, UnfadingTheme present).
- Pre-v5 Sprint 51 / 140-test narrative relocated to `docs/exec-plans/sprint-history-pre-v5.md` with explicit unverified-archive warning.
- `docs/references/coding-conventions.md` header amended with v5.6 / round 2 compliance note.
- `SKILLS.md` S-17 opening amended to clarify forward-looking scope.

## Governance notes

- `.gitignore` updated (selective un-gitignore of `workspace/ios/{App,Features,Shared,Tests}/` + `project.yml`) in pre-round commit `44e2a1d` — base commit for this round.
- Round lock: `context_harness/operator/locks/round_foundation_reset_r1.lock` status `active`, base_commit `44e2a1d`.
- One lock event logged so far: `created`.
- No amendments required during this round — base whitelist was sufficient for all deliverables.

## Capture exceptions

- `UnfadingCardBackground.swift` originally used `SwiftUI.Color.black.opacity(0.06)` which tripped the Color-grep after first pass. Captured in a second round of work: added `UnfadingTheme.Color.shadow` + `UnfadingTheme.Color.pinShadow` tokens and replaced inline usage in `UnfadingCardBackground.swift` and `MemoryPinMarker.swift`. Tests re-run and still passed 28/28.
- No other protocol exceptions.

## Next

Codex Operator writes verdict at `context_harness/reports/round_foundation_reset_r1/verdict.md`. `gate_evidence.json` assembly + `close` follow.
