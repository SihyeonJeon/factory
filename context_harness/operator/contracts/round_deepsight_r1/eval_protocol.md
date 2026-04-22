# round_deepsight_r1 Evaluation Protocol

## Purpose

This protocol evaluates a contract-only design analysis round. It verifies that the round produced reliable planning artifacts from the Deepsight input without changing product code.

Evidence capture is factual only. The capture report must not use verdict language such as `PASS`, `BLOCKER`, `ADVISORY`, `acceptable`, or `regression`.

## Inputs

Read-only source inputs:

- `docs/design-docs/travel_deepsight/Unfading Prototype.html`
- `docs/design-docs/travel_deepsight/check.png`
- `docs/design-docs/travel_deepsight/debug.png`

Reference documents:

- `docs/design-docs/design-revision-workflow.md`
- `context_harness/prd/ui_ux_screen_contract.md`
- `docs/design-docs/ios-architecture.md`
- `docs/references/coding-conventions.md`

Round deliverables:

- `docs/design-docs/deepsight_tokens.md`
- `docs/design-docs/deepsight_gap_analysis.md`
- `docs/design-docs/deepsight_slicing_manifest.md`

## Evidence Capture Checklist

Claude Code captures factual evidence and writes it to:

`context_harness/reports/round_deepsight_r1/evidence/contract_capture.md`

The evidence report must include:

- Source input file paths and SHA-256 hashes
- Deliverable file paths and SHA-256 hashes
- Confirmation that raw Deepsight inputs were not modified
- Confirmation that no Swift files changed
- Confirmation that `workspace/ios/project.yml`, `Package.swift`, and test files were not changed
- Section inventory for each deliverable
- Whether `deepsight_tokens.md` includes color, typography, spacing/radius, component token, and open-question sections
- Whether `deepsight_gap_analysis.md` follows the Phase 1 categories from `design-revision-workflow.md`
- Whether `deepsight_slicing_manifest.md` follows Phase 3 ordering: tokens, navigation if needed, screen clusters, accessibility/HIG sweep
- Any missing source information that prevented deterministic extraction

## Evidence Language Rules

Permitted evidence wording:

- "`<file>` exists"
- "`<file>` has SHA-256 `<hash>`"
- "`<section>` is present"
- "`<section>` is absent"
- "`git diff --name-only` shows `<path>`"
- "Source file hash before and after capture is unchanged"

Forbidden evidence wording:

- `PASS`
- `BLOCKER`
- `ADVISORY`
- `acceptable`
- `regression`
- "good enough"
- any final interpretation of whether the round succeeded

## Verdict Split

Codex writes the interpretation and verdict separately at:

`context_harness/reports/round_deepsight_r1/verdict.md`

The verdict may use `PASS`, `BLOCKER`, and `ADVISORY`, but every finding must cite evidence from `contract_capture.md` or a hashed deliverable file.

## Insufficient Evidence

If the evidence capture cannot verify a required item, the capture report records the missing fact and the file or command that failed to provide it. Codex decides whether the missing evidence is a blocker in the verdict.
