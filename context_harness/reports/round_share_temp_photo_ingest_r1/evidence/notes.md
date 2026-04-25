# round_share_temp_photo_ingest_r1 Evidence Notes

## Defect
- Defect ID: round_share_temp_photo_ingest_r1
- User-visible failure: Share Extension temp-file photo deep links (`unfading://composer?photo=/tmp/...jpg`) reached the composer without a PHAsset identifier, so the composer photo input appeared empty.
- Target files / line ranges: `workspace/ios/App/ComposerLaunchRoute.swift` lines 3-16, 19-29; `workspace/ios/Features/Home/MemoryComposerSheet.swift` lines 26-40, 163-215, 233-255, 621-630; `workspace/ios/Features/Home/MemoryComposerState.swift` lines 37, 58-103, 322-356, 406-440; `workspace/ios/Tests/ComposerLaunchRouteTests.swift` lines 4-15; `workspace/ios/Tests/MemoryComposerStateTests.swift` lines 89-101.

## Code Axis
- Reviewer: Codex Verifier fresh session (dispatch-2), separate from implementer Codex (dispatch-1).
- Result: PASS
- Evidence:
  - A1 tempFilePath route/state/render path: `ComposerLaunchPhotoReference` has `.tempFilePath(String)` and parses absolute/file URLs as temp files in `ComposerLaunchRoute.swift` lines 3-16. `MemoryComposerSheet` passes `sharedPhotoReference?.tempFilePath` into `MemoryComposerState` at lines 34-40 and exposes the enum helper at lines 627-630. `MemoryComposerState` stores `sharedTempImageURL` at lines 37 and 93 via `tempImageURL(from:)` lines 435-440. The photo section renders temp images first at `MemoryComposerSheet.swift` lines 211-215, and `sharedTempImageTile` loads `UIImage(contentsOfFile:)` and displays it at lines 237-251.
  - A2 assetIdentifier path preserved: `MemoryComposerSheet` still passes `sharedPhotoReference?.assetIdentifier` at line 37, the helper still returns only `.assetIdentifier` values at lines 621-625, and `MemoryComposerState` still seeds `selectedPhotos` from `sharedAssetIdentifier` with `PhotosPickerItem(itemIdentifier:)` at lines 78-79. The asset test asserts `selectedPhotos.first?.itemIdentifier` and nil temp URL in `MemoryComposerStateTests.swift` lines 96-101.
  - A3 tests added: `ComposerLaunchRouteTests.swift` lines 5-15 cover `/tmp/foo.jpg` as `.tempFilePath` and identifier as `.assetIdentifier`; `MemoryComposerStateTests.swift` lines 89-101 cover temp file state conversion and asset identifier preservation.
- Reject reason, if FAIL: n/a

## Runtime Axis
- Device/simulator: iOS Simulator `iPhone 17 Pro`, device id `00FCC049-D60A-4426-8EE3-EA743B48CCF9`, iOS 26.4 (`23E244`), from xcresult device metadata.
- Scenario: `workspace/ios/.deriveddata/r63/Test-R63.xcresult` test plan review for deep-link route parsing and composer state conversion; real simulator tap-to-photo/share-extension smoke not required by verifier per handoff constraint.
- Result: PASS
- Screenshot/video/xcresult: `workspace/ios/.deriveddata/r63/Test-R63.xcresult`; test plan `MemoryMap` result `Passed`; passedTests `232`, failedTests `0`, skippedTests `18`. Newly relevant PASS cases: `ComposerLaunchRouteTests/test_composerPhotoPathParsesAsTempFilePath()`, `ComposerLaunchRouteTests/test_composerPhotoIdentifierParsesAsAssetIdentifier()`, `MemoryComposerStateTests/test_temp_file_path_initializes_shared_temp_image_url()`, `MemoryComposerStateTests/test_asset_identifier_initializes_selected_photo_item()`.
- Reject reason, if FAIL: n/a

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_share_temp_photo_ingest_r1.lock` exists with `round_id` `round_share_temp_photo_ingest_r1`, status `active`, and hashes for `spec.md`, `file_whitelist.txt`, `acceptance.md`, and `eval_protocol.md`.
- Acceptance count <= 3: yes. `acceptance.md` defines A1, A2, A3 only.
- Author != verifier: yes. `eval_protocol.md` names implementer Codex dispatch-1 as Author and separate fresh Codex dispatch-2 as Verifier; this notes file was written by the verifier fresh session.
- Result: PASS
- Reject reason, if FAIL: n/a
- File whitelist check: PASS. Observed changed/new files are within `context_harness/operator/contracts/round_share_temp_photo_ingest_r1/file_whitelist.txt` lines 1-12: `MemoryComposerSheet.swift`, `MemoryComposerState.swift`, `MemoryComposerStateTests.swift`, `ComposerLaunchRouteTests.swift`, round contract files, and this `evidence/notes.md`. `ComposerLaunchRoute.swift` is whitelisted at line 3 and was reviewed even though it did not appear modified in current `git status`.

## Handoff
- Commit/push delegated to Claude Code: yes
