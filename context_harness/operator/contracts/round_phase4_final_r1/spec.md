# round_phase4_final_r1 Spec

## Goal

Integrate the R26-R60 product state into a single 2026-04-24 operator snapshot, publish the final Phase 4 release notes and TestFlight submission checklist, and verify the final TestFlight-prep commands without changing iOS source code.

## Scope

- Update `docs/product-specs/launchability-review-2026.md` to reflect the full R26-R60 state with Phase 1-4 checklists.
- Add `docs/product-specs/phase4_release_notes_2026-04-24.md` for R51-R60 release-facing changes.
- Rewrite `context_harness/SESSION_RESUME.md` as the R26-R60 final summary, including the feedback stream and deferred operator actions.
- Add `docs/deploy/testflight_submission_checklist_2026-04-24.md`.
- Re-run the requested R60 regression command with `.deriveddata/r60/Test-R60.xcresult`.
- Re-validate `workspace/ios/scripts/archive.sh` and `workspace/ios/scripts/export-options.plist`.
- Record evidence under `context_harness/reports/phase4_final/evidence/`.

## Non-Goals

- No Swift, project, plist, or script source edits.
- No Apple dashboard changes.
- No real archive signing or upload.
- No backend/provider configuration changes.

## Acceptance

- Launchability review, Phase 4 release notes, TestFlight checklist, and session resume are updated truthfully.
- `round_phase4_final_r1` contract folder, `2026-04-24_phase4_final.md`, and `reports/phase4_final/evidence/` exist.
- `bash -n workspace/ios/scripts/archive.sh` passes.
- `plutil -lint workspace/ios/scripts/export-options.plist` passes.
- The requested R60 `xcodebuild test` command is executed and the actual outcome is captured without overstating success.
