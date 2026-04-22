# Deepsight Slicing Manifest

## Source Inventory

| Source | SHA-256 | Notes |
|---|---|---|
| `docs/design-docs/travel_deepsight/Unfading Prototype.html` | `sha256:df8fe6badd57d17805a36385c1d9f62efd4d964efca3aa7bdc8d9c2189cb471e` | Primary source for scenes, tokens, and interaction notes. |
| `docs/design-docs/travel_deepsight/check.png` | `sha256:cb14f4bb14080f84d8c1b8ef4cce095505f778548ab998a6514038da7242e614` | Confirms eight-screen overview and high-level token panel. |
| `docs/design-docs/travel_deepsight/debug.png` | `sha256:0bfe72e4668458114180ea91d60ae019c99e46994ea7326ba7ae33c855947d92` | Low-signal image; no additional slicing input extracted. |

## Slicing Principles

- Follow `docs/design-docs/design-revision-workflow.md` Phase 3.
- One implementation round should affect at most 1-2 app screens where practical.
- Token/theme work comes first so later screen slices share stable inputs.
- Navigation work comes before screen redesign if Calendar or Group Hub placement changes.
- Screen slices should keep file whitelists narrow and avoid unrelated refactors.
- Accessibility and HIG review should be a final sweep after visual/interaction slices land.
- Raw Deepsight inputs stay read-only; derived contracts and implementation briefs reference hashes.

## Proposed Sequence

1. **Contract update round**: update product/design contracts from this gap analysis after human approval.
2. **Token/theme round**: establish native theme tokens for Deepsight palette, radius scale, text colors, sheet/card/chip surfaces, and selected marker states.
3. **Navigation round**: decide and implement root navigation placement for Map, Calendar, Rewind, and Group Hub if the product accepts Deepsight's first-class Calendar.
4. **Map shell round**: map default state, top chrome, sheet defaults, FAB, filter chips, and map controls.
5. **Map selected-context round**: cluster selected and pin selected states, including raised sheet, selected marker styling, clear action, and filtered content.
6. **Memory detail round**: member contribution cards, emotion/cost/location sections, and previous/next context navigation.
7. **Memory composer round**: photo grid, source options, inferred place/time confirmation UI, and selected-context entry paths.
8. **Calendar round**: month/year picker, day memory dots, selected-date event cards, and cost summary.
9. **Rewind round**: immersive rewind card, place-sensitive reminder affordance, and share/shareable-card behavior.
10. **Group Hub round**: cover/avatar header, mode toggle, member/invite management, map theme/pin pack/premium surfaces.
11. **Accessibility/HIG sweep**: VoiceOver labels/order, 44pt targets, Dynamic Type, Korean copy, and visual QA across redesigned screens.

## Sprint Slices

| Slice | Primary output | Screens affected | Dependencies |
|---|---|---|---|
| Contract update | Updated `ui_ux_screen_contract.md`, `ios-architecture.md`, coding-convention token notes, and round acceptance file | None directly | Human approval of Deepsight direction |
| Token/theme | Native theme source of truth and token mappings | Shared | Contract update |
| Navigation | Root routing model and tab/surface placement | Map, Calendar, Rewind, Group Hub | Contract update |
| Map shell | Default map browsing surface | Main Map | Token/theme, navigation if changed |
| Map selected context | Cluster selected and pin selected map states | Main Map states | Map shell |
| Memory detail | Detail reading surface | Memory Detail | Token/theme |
| Memory composer | Creation flow | Create/Edit Memory | Token/theme, selected-context decisions |
| Calendar | Dedicated calendar browsing | Calendar | Navigation decision |
| Rewind | Rewind surface | Rewind | Token/theme |
| Group Hub | Group management and mode presentation | Group Hub | Navigation decision, token/theme |
| Accessibility/HIG sweep | Cross-screen quality and native compliance | All redesigned screens | All prior slices |

## Dependencies

- Human approval is needed before product contract changes that alter navigation or screen inventory.
- Theme source of truth must be resolved before visual implementation because docs require centralized `UnfadingTheme` usage, but targeted search did not find an active Swift theme file.
- Calendar placement must be decided before implementing Calendar visuals.
- Map selected-context behavior depends on stable bottom-sheet states.
- Composer confirmation behavior depends on place/time inference contracts already present in `ui_ux_screen_contract.md`.
- Accessibility acceptance criteria should be attached to each screen brief and rechecked in the final sweep.

## Non-Goals

This manifest does not:

- Implement Swift changes
- Change navigation by itself
- Approve the Deepsight redesign for production
- Decide exact Korean copy
- Decide exact native map styling feasibility
- Replace per-round file whitelists or acceptance criteria

## Open Questions

- Should the token/theme round create a new `UnfadingTheme.swift`, restore an expected missing file, or map tokens into another existing theme mechanism?
- Should Calendar be restored as a first-class tab/surface, or stay reachable from Map/Rewind flows?
- Which map palette is product-approved for native implementation: default, warm, vintage, dark, or a subset?
- Should Group Hub include settings/premium controls, or should those remain separate in a future settings surface?
- Should sheet snap points be exact `22%/52%/88%` values, or native approximations derived during implementation?
- Does `debug.png` have intended content that should be re-exported before implementation planning continues?
