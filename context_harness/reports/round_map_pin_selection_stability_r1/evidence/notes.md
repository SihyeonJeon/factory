# round_map_pin_selection_stability_r1 Evidence Notes

## Defect
- Defect ID: round_map_pin_selection_stability_r1
- User-visible failure: Place picker confirmation could save the closest POI coordinate instead of the user-selected map center coordinate.
- Target files / line ranges:
  - `workspace/ios/Features/Composer/PlacePickerSheet.swift` lines 124-139
  - `workspace/ios/Features/Composer/NearbyPlaceService.swift` lines 62-68
  - `workspace/ios/Tests/NearbyPlaceServiceTests.swift` lines 59-75

## Code Axis
- Reviewer: Codex Verifier fresh session, separate from implementer.
- Result: PASS
- Evidence:
  - `PlacePickerSheet.swift:124-129` confirms `let center = currentCenterCoordinate()` followed by `place = match.pickedPlace(at: center)`.
  - `NearbyPlaceService.swift:62-68` preserves existing `var pickedPlace: PickedPlace { PickedPlace(name: name, coordinate: coordinate, address: address) }` and adds `func pickedPlace(at coordinate: CLLocationCoordinate2D) -> PickedPlace { PickedPlace(name: name, coordinate: coordinate, address: address) }`.
  - `NearbyPlaceServiceTests.swift:59-75` adds `test_pickedPlace_at_uses_provided_coordinate_not_poi()`, with POI coordinate `(37.501, 127.002)`, center `(37.500, 127.000)`, name/address asserted from match, and picked coordinate asserted equal to center within `0.000001`.
- Reject reason, if FAIL: n/a

## Runtime Axis
- Device/simulator: iOS Simulator, iPhone 17 Pro, iOS 26.4, device id `00FCC049-D60A-4426-8EE3-EA743B48CCF9`.
- Scenario: `xcodebuild test` result bundle at `workspace/ios/.deriveddata/r66/Test-R66.xcresult`; focused regression test confirms provided center coordinate is used instead of POI coordinate.
- Result: PASS
- Screenshot/video/xcresult:
  - xcresult summary: result `Passed`, total `257`, passed `239`, failed `0`, skipped `18`, expected failures `0`.
  - `NearbyPlaceServiceTests` suite result: `Passed`.
  - `NearbyPlaceServiceTests/test_pickedPlace_at_uses_provided_coordinate_not_poi()` result: `Passed`, duration `0.00059s`.
- Reject reason, if FAIL: n/a

## Process Axis
- Contract locked: yes, `context_harness/operator/locks/round_map_pin_selection_stability_r1.lock` exists with `status: active` and hashes for `spec.md`, `file_whitelist.txt`, `acceptance.md`, and `eval_protocol.md`.
- Acceptance count <= 3: yes, `acceptance.md` has A1-A3 only.
- Author != verifier: yes, eval protocol states Author `Codex Implementer fresh session (dispatch-1)` and Verifier `별도 Codex Verifier fresh session (dispatch-2)`; this verification was performed as a fresh Codex Verifier session.
- Result: PASS
- Reject reason, if FAIL: n/a
- Whitelist scope: PASS. Source/contract artifacts are in `file_whitelist.txt`; lock infra (`context_harness/operator/locks/<round_id>.lock`, `.events.jsonl`) is excluded from whitelist enforcement per R63/R64/R65 precedent.

## Handoff
- Commit/push delegated to Claude Code: yes
- Overall: OK to handoff
