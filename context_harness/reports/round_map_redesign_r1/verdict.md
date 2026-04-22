# Verdict — round_map_redesign_r1

**Author:** Codex Operator
**Timestamp:** 2026-04-22T16:28:08Z
**Evidence:** `context_harness/reports/round_map_redesign_r1/evidence/contract_capture.md` (`sha256:79605c1d2de27e9887cca586690b95e202c639d9c121f8032e8dfa5acd53a4c7`)

## Summary

Overall verdict: PASS with ADVISORY items only. R4 delivers the reusable map-shell components, rewrites the main map into a Deepsight-style layered surface, adds persistent bottom-sheet state, filter chips, selected-pin state wiring, and tests. The two Codex review blockers were fixed in-round by Codex dispatch: the FAB is now visible above the sheet in the post-fix runtime screenshot, and the bottom-sheet drag gesture is attached to the visible sheet frame rather than the full-screen alignment frame. Build/test evidence records 51/51 tests passing.

## Acceptance criteria check

| Criterion | Verdict | Citation |
|---|---|---|
| `UnfadingBottomSheet.swift` exists | PASS | Evidence `contract_capture.md` section `## File hashes`. |
| `UnfadingFilterChip.swift` exists | PASS | Evidence `contract_capture.md` section `## File hashes`. |
| `MemorySelectionState.swift` exists | PASS | Evidence `contract_capture.md` section `## File hashes`. |
| Bottom sheet, filter chip, and selection state each have production + test references | PASS | Evidence `contract_capture.md` section `## Acceptance grep`, reusable-module proof. |
| Forbidden color patterns absent in touched files | PASS | Evidence `contract_capture.md` section `## Acceptance grep`. |
| English user-facing literals absent in touched views | PASS | Evidence `contract_capture.md` section `## Acceptance grep`. |
| `xcodebuild test` exits 0 | PASS | Evidence `contract_capture.md` section `## Test run`. |
| Test count is at least 44 | PASS | Evidence `contract_capture.md` section `## Test run` records 51 tests. |
| Runtime screenshot of new Map default state captured | PASS | Evidence `contract_capture.md` section `## Runtime screenshots`; `02_map_after_fab_fix.png` confirms post-fix default map with visible FAB. |
| Runtime selected-pin screenshot captured | ADVISORY | Evidence `contract_capture.md` section `## Capture exceptions`; pin-selection screenshot was not automated, while `MemorySelectionStateTests` cover state transitions. |
| Codex peer review cycle recorded and blockers fixed | PASS | Evidence `contract_capture.md` section `## Codex code review cycle`; transcripts `codex_r4_codereview.log` and `codex_r4_fixfab.log`. |

## Blockers (post-fix: expect 0)

None.

## Advisories (your 4 from codereview, carry forward)

1. Inner-scroll versus sheet-drag gesture contention may appear when summary content grows. Revisit when the bottom sheet contains richer archive content.
2. Expanded-state FAB policy is now implemented as hidden while expanded. Keep this behavior explicit in future map selected-context work.
3. Sample data can still surface English through `SampleMemoryPin.title` or related model data when pins are selected. This needs the planned data-localization pass.
4. Filter chips expose labels and selected state, but richer VoiceOver hints or values should be considered in a later accessibility sweep.

## Recommendation for close

PASS. Proceed to gate_evidence.json assembly and close. No blockers remain; carry the advisories into retro and future map/accessibility rounds.
