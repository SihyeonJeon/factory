# round_deepsight_r1 Acceptance Criteria

## Required Deliverables

The round is ready for evaluation only when all three deliverable documents exist:

- `docs/design-docs/deepsight_tokens.md`
- `docs/design-docs/deepsight_gap_analysis.md`
- `docs/design-docs/deepsight_slicing_manifest.md`

## Document Criteria

### Tokens

`deepsight_tokens.md` must include:

- Source inventory with hashes
- Color token extraction or explicit unknowns
- Typography token extraction or explicit unknowns
- Spacing and radius observations or explicit unknowns
- Component token observations or explicit unknowns
- Open questions

### Gap Analysis

`deepsight_gap_analysis.md` must map to `docs/design-docs/design-revision-workflow.md` Phase 1 and include:

- Screen inventory
- Navigation
- Component tokens
- Interaction
- Copy
- Accessibility
- Impacted contracts
- Open questions

### Slicing Manifest

`deepsight_slicing_manifest.md` must order future implementation work according to Phase 3:

1. Token and theme contract work
2. Navigation work, if needed
3. Screen clusters, with each implementation round limited to 1-2 screens where practical
4. Accessibility and HIG sweep

## Change Constraints

The round must not change:

- Swift files under `workspace/ios/`
- `workspace/ios/project.yml`
- `Package.swift`
- Test files or test configuration
- Raw input files under `docs/design-docs/travel_deepsight/`

## Raw Input Integrity

The SHA-256 hashes of the raw Deepsight inputs must match the source inventory in `spec.md`:

- `docs/design-docs/travel_deepsight/Unfading Prototype.html`
- `docs/design-docs/travel_deepsight/check.png`
- `docs/design-docs/travel_deepsight/debug.png`

Any raw input hash mismatch is a round blocker.

## Evidence And Verdict

Required evaluation artifacts:

- Evidence report: `context_harness/reports/round_deepsight_r1/evidence/contract_capture.md`
- Verdict report: `context_harness/reports/round_deepsight_r1/verdict.md`

The evidence report must follow `eval_protocol.md` and remain factual-only. The verdict report must classify findings as `PASS`, `BLOCKER`, or `ADVISORY` with citations to evidence.

## Close Criteria

The round may close when:

- All required deliverables exist
- Required sections are present
- No forbidden files changed
- Raw input hashes match
- Evidence report exists
- Verdict report exists
- Gate evidence for Gates 1-4 is recorded according to the active checker schema
- Gate 5 process-integrity checks pass
