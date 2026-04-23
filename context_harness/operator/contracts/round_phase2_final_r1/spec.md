# round_phase2_final_r1 Spec

## Goal

Integrate the R26-R39 Phase 1 + Phase 2 + launch-prep outcomes into a single 2026-04-24 operator snapshot, produce user-facing release notes, and verify the TestFlight preparation scripts plus final regression command in the current workspace-write session.

## Scope

- Update `docs/product-specs/launchability-review-2026.md` to reflect the integrated R26-R39 state.
- Add `docs/product-specs/phase2_release_notes_2026-04-24.md` for device/TestFlight verification.
- Rewrite `context_harness/SESSION_RESUME.md` as the 2026-04-24 integrated summary.
- Run the requested R40 `xcodebuild test` command with `.deriveddata/r40/Test-R40.xcresult`.
- Attempt screenshot harvest from the R40 result bundle into `context_harness/reports/phase2_final/evidence/`.
- Validate `workspace/ios/scripts/archive.sh` and `workspace/ios/scripts/export-options.plist`.
- Record Phase 3 deferred items only; no source-code changes.

## Non-Goals

- No Swift or project source edits.
- No signing changes, Apple account setup, or real TestFlight upload.
- No backend work for Apple Sign in, receipt validation, or HIBP automation.

## Acceptance

- Three docs are updated: launchability review, release notes, session resume.
- `round_phase2_final_r1` contract folder, phase2 final meeting file, and `reports/phase2_final/evidence/` exist.
- `bash -n scripts/archive.sh` passes.
- `plutil -lint scripts/export-options.plist` passes.
- Requested `xcodebuild test` command is executed and its real outcome is captured without overstating success.
- Deferred list explicitly includes Apple Sign in, Edge Function receipts, HIBP toggle, and TestFlight upload under Phase 3.
