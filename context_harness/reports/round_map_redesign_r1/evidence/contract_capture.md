# Evidence — round_map_redesign_r1

**Timestamp:** 2026-04-23T01:30Z
**Capture protocol:** `context_harness/operator/contracts/round_map_redesign_r1/eval_protocol.md`

## File hashes

| File | SHA |
|---|---|
| `workspace/ios/Shared/UnfadingBottomSheet.swift` (new) | sha256:6e4d4c7492484d17c8f33b582ddcb69dd581afdf42bb29d272bad47d5d548504 |
| `workspace/ios/Shared/UnfadingFilterChip.swift` (new) | sha256:d4175b11a8b6d686dfb23f952265ad5c7f72aecfe5000af5c1d7feaeb74a34e9 |
| `workspace/ios/Shared/UnfadingLocalized.swift` (+Home filters, +Summary.selectedBodyTemplate, +selectedEyebrow) | sha256:33ffa00b20d8b3a9e0598d3848f6fb2c1641a14b0dabb44552849d5bd6d2b820 |
| `workspace/ios/Features/Home/MemoryMapHomeView.swift` (rewrite: ZStack, FAB, filter row, group chip, search, persistent sheet) | sha256:1b1c244825449733a396393f40166f90d8d71e90ecbbddf83f5ae16e2529b91c |
| `workspace/ios/Features/Home/MemorySummaryCard.swift` (+selectedPin param) | sha256:772fad9731827974ecb72a9321973583122bb04437fb2f0b914106b40a899228 |
| `workspace/ios/Features/Home/MemorySelectionState.swift` (new) | sha256:f90ea64e017d71d80a7398ed41c96b58164557e1209ac6e7a9c031b132452c11 |
| `workspace/ios/Tests/UnfadingBottomSheetTests.swift` (new, 4 tests) | sha256:ecf26c860a567bec9e157ceda1fc6455e7cd866a7f69ce78bd42db8959e56085 |
| `workspace/ios/Tests/UnfadingFilterChipTests.swift` (new, 3 tests) | sha256:97e50354585ff60917dd8ea261c9a89c88344abfe4e76833e2db30c374f734b0 |
| `workspace/ios/Tests/MemorySelectionStateTests.swift` (new, 10 tests) | sha256:97557d322ce2ce897d6b62c058c471db6783a59177b35285c076b66a305fbab5 |

## Test run
- Exit 0, `** TEST SUCCEEDED **`
- test_count 51 (baseline 34 + 17 new)
- Log sha256:ec02165e65093bfe9f7ca13e5807a561aa5f417edd30b57b1333bd509e79e4bc

## Runtime screenshots
- `01_map_default.png` — initial capture BEFORE FAB fix; map surface with 그룹 chip / search / 5 filter chips / persistent sheet at default snap. FAB missing. sha256:3a48fbd624aff2224800224148853a54ee14236c20da06a4ac029cf101622a0e
- `02_map_after_fab_fix.png` — capture AFTER the Codex-applied FAB fix; "+ 추억 기록" FAB now visible bottom-right above the sheet. All deepsight chrome elements present. sha256:910940e689e3934645d13f6baaa09e111ac04518c4ff97615e84b6f7fe319306

## Codex code review cycle (real peer review)
- Transcript: `context_harness/operator/codex_transcripts/codex_r4_codereview.log`
- Codex identified **2 blockers** (FAB invisible at runtime; drag gesture hit area steals map panning) + **4 advisories** (drag vs inner scroll contention; expanded-state FAB policy; selected-pin English leak via model data; filter-chip a11y hints).
- Fix dispatched to Codex (NOT edited by operator per user directive): `context_harness/operator/codex_transcripts/codex_r4_fixfab.log`. Codex applied diagnosed fix: moved FAB to parent ZStack with zIndex(2), dynamic bottom padding from sheet height, hidden on expanded snap; restructured bottom sheet drag gesture attachment to the visible sheet frame only.
- Post-fix build SUCCEEDED + 51/51 tests PASS + runtime screenshot visually confirms FAB visible.

## Acceptance grep
- Forbidden colors in touched files (excluding UnfadingTheme.swift): 0
- English user-facing literals in Text/Label/accessibility in touched views: 0
- Reusable-module proof: UnfadingBottomSheet used by MemoryMapHomeView + BottomSheetTests; UnfadingFilterChip used by MemoryMapHomeView + FilterChipTests; MemorySelectionState used by MemoryMapHomeView + SelectionStateTests

## Advisories carried forward
- Sample data still English via `SampleMemoryPin.title` (surfaces when pin selected) — needs R11 data-localization pass
- Inner-scroll vs sheet-drag gesture contention possible when summary content grows — revisit in R5 composer or later
- Filter chip a11y hints not yet added (chip state is inferrable but could be richer)

## Capture exceptions
- Pin-selection runtime screenshot not automated (xcrun simctl lacks tap). Selection state transitions are unit-tested in MemorySelectionStateTests. R12 launchability will add XCUITest tour.
