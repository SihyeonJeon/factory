# round_deepsight_r1 Specification

## Scope

This is a contract-only design analysis round for the Deepsight travel redesign input.

The round produces three planning artifacts under `docs/design-docs/`:

- `docs/design-docs/deepsight_tokens.md`
- `docs/design-docs/deepsight_gap_analysis.md`
- `docs/design-docs/deepsight_slicing_manifest.md`

These artifacts become the input contract for later implementation rounds. This round does not implement UI changes.

## Input Source Inventory

Raw Deepsight inputs are read-only for this round.

| Source | SHA-256 |
|---|---|
| `docs/design-docs/travel_deepsight/Unfading Prototype.html` | `sha256:df8fe6badd57d17805a36385c1d9f62efd4d964efca3aa7bdc8d9c2189cb471e` |
| `docs/design-docs/travel_deepsight/check.png` | `sha256:cb14f4bb14080f84d8c1b8ef4cce095505f778548ab998a6514038da7242e614` |
| `docs/design-docs/travel_deepsight/debug.png` | `sha256:0bfe72e4668458114180ea91d60ae019c99e46994ea7326ba7ae33c855947d92` |

## Deliverable Structure

### `deepsight_tokens.md`

Required sections:

- `## Source Inventory` - source files and hashes used for extraction
- `## Color Tokens` - discovered colors, semantic role candidates, and mapping notes
- `## Typography Tokens` - font sizes, weights, line-height notes, and semantic role candidates
- `## Spacing And Radius` - spacing scale, corner radii, and layout rhythm observations
- `## Component Tokens` - repeated visual components, controls, cards, bars, or navigation elements
- `## Open Questions` - token values that cannot be determined from the available inputs

### `deepsight_gap_analysis.md`

Required sections aligned to `docs/design-docs/design-revision-workflow.md` Phase 1:

- `## Source Inventory`
- `## Screen Inventory`
- `## Navigation`
- `## Component Tokens`
- `## Interaction`
- `## Copy`
- `## Accessibility`
- `## Impacted Contracts`
- `## Open Questions`

The gap analysis must compare current Unfading contracts/code expectations against the Deepsight input where enough information exists. Unknowns should be explicit, not guessed.

### `deepsight_slicing_manifest.md`

Required sections:

- `## Source Inventory`
- `## Slicing Principles`
- `## Proposed Sequence`
- `## Sprint Slices`
- `## Dependencies`
- `## Non-Goals`
- `## Open Questions`

The proposed sequence must follow the design revision workflow Phase 3 order:

1. Token extraction and theme contract updates
2. Navigation changes, if needed
3. Screen clusters, limited to 1-2 screens per implementation round
4. Accessibility and HIG sweep

## Non-Goals

This round must not:

- Modify Swift source files under `workspace/ios/`
- Modify `workspace/ios/project.yml`
- Modify `Package.swift`
- Modify test files or test configuration
- Modify raw Deepsight input files under `docs/design-docs/travel_deepsight/`
- Create implementation sprint code
- Create `spec.amendment.*` or any amendment file
- Decide final product approval for the redesign

## Expected Follow-Up

Later rounds may use these artifacts to create product contract updates, implementation briefs, Swift changes, runtime evidence, and visual evaluation. Those later rounds require their own contracts and locks.
