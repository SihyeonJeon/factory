# Evidence — round_composer_redesign_r1

**Timestamp:** 2026-04-23T02:20Z
**Mode:** v5.7 (Swift impl delegated to Codex; operator did not edit Swift)

## Files (all Codex-authored via dispatch)

| File | SHA |
|---|---|
| `workspace/ios/Shared/UnfadingPhotoGrid.swift` (new) | sha256:4748d811afd125daf21fa163eea8bb9a4f2d7d3e7f6f245855b42b6837d429e9 |
| `workspace/ios/Features/Home/MemoryComposerSheet.swift` (rewrite) | sha256:5909cb330d46dd181b96ea49ca0814203c1fdc2b07c2d6742b1d3670d3a23772 |
| `workspace/ios/Features/Home/MemoryComposerState.swift` (new) | sha256:c5dd0b27bf368828ae054ffdd59d48059b090877005e6c62f6265fa6dca30a3a |
| `workspace/ios/Shared/UnfadingLocalized.swift` (+Composer+PhotoGrid keys) | sha256:8d1ef78788778529e0d8550386e41bbd6915d7cc88d1a86490f5420ad00495b4 |
| `workspace/ios/Tests/UnfadingPhotoGridTests.swift` | sha256:ef8b2265af44fb0a0d0a5980a47ce31dce55d045a63a09a9fed20f2bf004a611 |
| `workspace/ios/Tests/MemoryComposerStateTests.swift` | sha256:67cddb374832d32aa0ffecc616cedb3bb4f9ecf00c1fd69087e43dbc00fca510 |

## Gate 1 — Code axis

- `xcodebuild test` exit 0
- test_count 60 (baseline 51 + 9 new)
- Log sha256:c454f8015772ca872733fb4296ae34fca5d87f3b9e1a8bc1b5bac8b8561b228b

## Gate 2 — Runtime functional axis

- Sim launch with `SIMCTL_CHILD_MEMORYMAP_EVIDENCE_MODE=manualPlacePicker`
- Composer opens + ManualPlacePickerSheet overlays
- Screenshot: `screenshots/01_composer_open.png` sha256:eaffe6fc660550119845945764259071434780a660ce6d7778b679bf0eb19798
- Observed: Korean throughout ("취소", "장소 선택", "장소 검색", "근처 장소", "상수 루프톱 / 제주 성산일출봉 / 여의도 한강공원"). PlaceSuggestion.id → Korean mapping via UnfadingLocalized.placeSuggestion() works end-to-end.
- Capture exception: full composer view (without sub-sheet overlay) not captured — existing evidence modes auto-route to sub-sheet. Addition of a "composer only" evidence mode is deferred.

## Gate 3 — UI/UX fidelity axis

- Composer uses warm sheet palette, coral primary CTAs
- Sections in deepsight-aligned order (사진/장소/시간/메모/감정)
- Manual place picker visible as Korean list with warm icons

## Gate 4 — Navigation + info axis

- Composer → place picker → dismissal chain works (observed via simctl launch)
- Nav title "새 추억" localized
- Save CTA uses `.unfadingPrimary`; disabled state gates on MemoryComposerState.isSaveEnabled

## Gate 5 — Process-context axis

- Operator did NOT directly edit Swift this round (per v5.7 §2)
- All Swift code authored by Codex via `codex exec` dispatch (`/tmp/codex_r6_impl.log` → persisted at codex_transcripts/)
- vibe-limit-checked comments present in touched Swift files (verified via grep `// vibe-limit-checked`)
- Dispatched prompt cited vibe-coding-limits-2026 items: silent try? suppression, [weak self], @MainActor, Dynamic Type, 44pt, English leaks

## Acceptance grep

- Forbidden colors (Color.white/black/accentColor/Color(red:) outside UnfadingTheme: **0**
- English literals in composer Text/Label/accessibility: **0**
- `// vibe-limit-checked:` comments: present in UnfadingPhotoGrid + MemoryComposerState + MemoryComposerSheet + tests

## Reusable module proof

- UnfadingPhotoGrid: production use in MemoryComposerSheet (photoSection); test in UnfadingPhotoGridTests
- MemoryComposerState: production use in MemoryComposerSheet (@StateObject); test in MemoryComposerStateTests

## Codex self-review (second dispatch, fresh session)

Second-session review accidentally re-implemented instead of reviewing (Codex interpreted prompt as continue-impl). Outcome: minor follow-up fixes (SwiftUI import + test item constructor) already absorbed; re-test after these fixes kept 60/60 green. No blockers surfaced from the (partial) review. A dedicated ADR for "how to prompt Codex for review-only without impl side-effects" is deferred to retro.

## Advisories carried forward
- No dedicated "composer-only" evidence mode (R7/R11 add)
- Full composer save flow has no backing persistence yet (R11)
- Date picker locale is forced `ko_KR` inline; candidate for a later localization token
