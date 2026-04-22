# Evidence — round_deepsight_r1 Contract Capture

**Author:** Claude Code Operator (evidence capture per STAGE_CONTRACT Stage 8)
**Capture protocol:** `context_harness/operator/contracts/round_deepsight_r1/eval_protocol.md`
**Scope:** factual observations only. No PASS/BLOCKER/ADVISORY language. Verdict authored separately by Codex Operator at `context_harness/reports/round_deepsight_r1/verdict.md`.

---

## Capture timestamp

2026-04-22T21:12Z (captured after Codex dispatch completed all 3 deliverables)

## Input sources (read-only, hashes as observed at capture time)

| Path | SHA-256 |
|------|---------|
| `docs/design-docs/travel_deepsight/Unfading Prototype.html` | `sha256:df8fe6badd57d17805a36385c1d9f62efd4d964efca3aa7bdc8d9c2189cb471e` |
| `docs/design-docs/travel_deepsight/check.png` | `sha256:cb14f4bb14080f84d8c1b8ef4cce095505f778548ab998a6514038da7242e614` |
| `docs/design-docs/travel_deepsight/debug.png` | `sha256:0bfe72e4668458114180ea91d60ae019c99e46994ea7326ba7ae33c855947d92` |

All three input source hashes match the hashes recorded in each of the 3 deliverable docs' `## Source Inventory` sections (cross-checked by reading those sections directly).

## Output deliverables

| Path | SHA-256 | Line count |
|------|---------|-----------:|
| `docs/design-docs/deepsight_tokens.md` | `sha256:638425b8c8aa5cbcf0826fc31980b31a8b5ebc0dd9ed6c669c03c6c7c9d9a59f` | 104 |
| `docs/design-docs/deepsight_gap_analysis.md` | `sha256:50ec2701eb394999a4f37a72fbc9c279b5232a696f3c10d83dfa56f8c2a83712` | 109 |
| `docs/design-docs/deepsight_slicing_manifest.md` | `sha256:16d02f0bc4b8b58a38d6db6d03f6266dd1fe5460daf1b1f6fadfc57b55fc7b18` | 78 |

## Required section presence (verified by heading grep on each deliverable)

### `deepsight_tokens.md`
- `## Source Inventory` — present
- `## Color Tokens` — present
- `## Typography Tokens` — present
- `## Spacing And Radius` — present
- `## Component Tokens` — present
- `## Open Questions` — present

### `deepsight_gap_analysis.md`
- `## Source Inventory` — present
- `## Screen Inventory` — present
- `## Navigation` — present
- `## Component Tokens` — present
- `## Interaction` — present
- `## Copy` — present
- `## Accessibility` — present
- `## Impacted Contracts` — present
- `## Open Questions` — present

### `deepsight_slicing_manifest.md`
- `## Source Inventory` — present
- `## Slicing Principles` — present
- `## Proposed Sequence` — present
- `## Sprint Slices` — present
- `## Dependencies` — present
- `## Non-Goals` — present
- `## Open Questions` — present

All required sections from the locked `spec.md` are present in each deliverable.

## No-Swift / no-project / no-test constraint

`git status --porcelain -uall` at capture time shows 15 changed/untracked entries; grep for `workspace/ios`, `project.yml`, `.swift`, or `Tests/` returned zero matches. Input sources under `docs/design-docs/travel_deepsight/` are tracked and unmodified in the working tree (no modification marks for the HTML or PNGs).

## State observation: `UnfadingTheme.swift` discrepancy

During targeted search for the theme file referenced in `deepsight_tokens.md` Open Questions, Claude Code Operator ran:

```
find workspace/ios -name "UnfadingTheme*"
```
→ returned no results.

```
find workspace/ios -name "*Theme*"
```
→ returned no results.

```
ls workspace/ios
```
→ `App/`, `Features/`, `MemoryMap.xcodeproj/`, `Shared/`, `Tests/`, `project.yml`

`workspace/ios/Shared/` exists and contains Swift files (e.g., `LocationPermissionStore.swift`, `SampleModels.swift`) but no file with `Theme` in the name.

Text references observed in non-Swift files:
- `SESSION_RESUME.md` — mentions `UnfadingTheme` in multiple historical sprint summaries (sprints 36, 7, etc.)
- `docs/references/coding-conventions.md` — prescribes `UnfadingTheme.primary` / `.textPrimary` / etc. as allowed; forbids inline `Color()` use
- `docs/design-docs/ios-architecture.md` — references `UnfadingTheme` as a theme token namespace
- `SKILLS.md` S-17 — references `UnfadingTheme` tokens in multiple checklist items
- `deepsight_tokens.md` Open Questions — notes the same state discrepancy

This is captured as factual state only. Whether it represents a product gap, a rename, a workspace reset, or a documentation drift is a verdict question for Codex.

## Checker state at capture

- Lock: `context_harness/operator/locks/round_deepsight_r1.lock` — `status: active`, `base_commit: 791874f719d5edb009e29a379967600ad0f2a54f`, `schema_version: 2`
- Event log: `context_harness/operator/locks/round_deepsight_r1.events.jsonl` — 1 event (`action: created`, same `base_commit`)
- Latest `gates` run (pre-capture): 27 passes / 1 advisory / 0 blockers

## Files touched this round (from `git status --porcelain -uall`)

Committed (since `base_commit`): none.

Working tree modifications:
- `context_harness/SESSION_RESUME.md` (whitelisted)
- `context_harness/operator/CHANGELOG.md` (whitelisted)
- `docs/exec-plans/process-log.jsonl` (whitelisted)

Untracked (new, since `base_commit`):
- `context_harness/operator/codex_transcripts/codex_author_contract.log` (whitelisted)
- `context_harness/operator/codex_transcripts/codex_author_deliverables.log` (whitelisted via `codex_round1_*` glob — will verify on next gates)
- `context_harness/operator/codex_transcripts/codex_round1_plan.log` (whitelisted)
- `context_harness/operator/contracts/round_deepsight_r1/acceptance.md`
- `context_harness/operator/contracts/round_deepsight_r1/convention_version.txt`
- `context_harness/operator/contracts/round_deepsight_r1/eval_protocol.md`
- `context_harness/operator/contracts/round_deepsight_r1/file_whitelist.txt`
- `context_harness/operator/contracts/round_deepsight_r1/lint_config.txt`
- `context_harness/operator/contracts/round_deepsight_r1/spec.md`
- `context_harness/operator/locks/round_deepsight_r1.events.jsonl`
- `context_harness/operator/locks/round_deepsight_r1.lock`
- `context_harness/operator/meetings/2026-04-22_round1_deepsight_plan.md`
- `context_harness/reports/round_deepsight_r1/evidence/checker_friction.md`
- `context_harness/reports/round_deepsight_r1/evidence/contract_capture.md` (this file)
- `docs/design-docs/deepsight_gap_analysis.md`
- `docs/design-docs/deepsight_slicing_manifest.md`
- `docs/design-docs/deepsight_tokens.md`

All entries match the effective whitelist (base + no amendments so far).

## Capture exceptions

None. Protocol followed without deviation.

---

Next step per STAGE_CONTRACT: Codex Operator writes verdict at `context_harness/reports/round_deepsight_r1/verdict.md` using this evidence + direct inspection of the deliverables. Gate 3 cross-agreement note + gate evidence assembly follow.
