---
round: round_composer_redesign_r1
stage: overall_planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round6-composer
contract_hash: none
created_at: 2026-04-23T02:00:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---

# Meeting — R6 Plan: Memory Composer Redesign

## Context
R5 (db47bb3) landed v5.7 governance (Swift impl = Codex dispatch). First real round under the new regime.

## Scope
Full redesign of `MemoryComposerSheet.swift` per deepsight spec:
- Photo grid (4-column) using PhotosUI `PhotosPicker` (iOS 16+ native)
- Inferred place + time confirmation UI with explicit "correct" affordances
- Emotion/mood tag cloud (UnfadingFilterChip-based)
- Section hierarchy matching deepsight: Photos → Place → Time → Note → Mood
- Primary save CTA using `.unfadingPrimary`
- Korean-native copy throughout

## Non-goals
- Real Supabase upload (R10/R11)
- Full asset management (this round: picker only, no crop/rotate)
- Place search integration (placeholder search sheet retained)

## Reusable assets touched/created
- Existing: UnfadingTheme / UnfadingLocalized / UnfadingPrimaryButtonStyle / UnfadingFilterChip / UnfadingCardBackground
- New: `UnfadingPhotoGrid.swift` — reusable 4-col photo grid with add button

## Acceptance
- Composer rendered fully in Korean
- Photo grid displays PhotosPicker items, 4 columns on compact Dynamic Type
- 44pt tap targets
- Zero inline colors
- ≥6 new tests (composer state transitions + photo grid binding)
- Runtime screenshot of redesigned composer

## Challenge Section

### Objection
PhotosPicker returns `PhotosPickerItem` async; loading data can fail silently. Mitigation: dispatch prompt must cite `vibe-coding-limits-2026` item on silent `try?` misuse (require `do-catch` + user-facing error).

### Risk
Full composer redesign is large. Split risk: if Codex produces 400+ lines in one dispatch, review becomes hard. Mitigation: request Codex to split output into `MemoryComposerSheet.swift` + `UnfadingPhotoGrid.swift` + `MemoryComposerState.swift` (state object) with clear APIs.

### Rejected alternative
Incremental refactor (keep current Form-based structure). Rejected because current structure is iOS Settings-style Form, not the deepsight sheet design.

### Uncertainty
Exact Korean wording for inferred-time/place UI — Codex first cut, iterate if Codex review finds issues.

## Decision
PROCEED. Dispatch Codex implementation with explicit vibe-coding-limits citations (items: silent error suppression, missing @MainActor consistency, a11y gaps, English leaks).
