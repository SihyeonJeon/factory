# round_phase3_final_r1 Spec

## Goal

Integrate the R26-R50 product state into a single 2026-04-24 operator snapshot, publish the final Phase 3 release notes, and verify the final TestFlight-prep commands without changing iOS source code.

## Scope

- Update `docs/product-specs/launchability-review-2026.md` to reflect the full R26-R50 state.
- Add `docs/product-specs/phase3_release_notes_2026-04-24.md` for device/TestFlight verification.
- Rewrite `context_harness/SESSION_RESUME.md` as the R26-R50 final summary.
- Re-run the requested R50 regression command with `.deriveddata/r50/Test-R50.xcresult`.
- Re-validate `workspace/ios/scripts/archive.sh` and `workspace/ios/scripts/export-options.plist`.
- Record evidence under `context_harness/reports/phase3_final/evidence/`.
- Keep the deferred list limited to App Store Connect registration, Apple team ID, HIBP toggle, and real-device TestFlight upload.

## Non-Goals

- No Swift, project, plist, or script source edits.
- No Apple dashboard changes.
- No real archive signing or upload.
- No backend/provider configuration changes.

## Acceptance

- Launchability review, Phase 3 release notes, and session resume are updated truthfully.
- `round_phase3_final_r1` contract folder, `2026-04-24_phase3_final.md`, and `reports/phase3_final/evidence/` exist.
- `bash -n workspace/ios/scripts/archive.sh` passes.
- `plutil -lint workspace/ios/scripts/export-options.plist` passes.
- The requested R50 `xcodebuild test` command is executed and the actual outcome is captured without overstating success.
