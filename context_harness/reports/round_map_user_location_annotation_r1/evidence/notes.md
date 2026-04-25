# round_map_user_location_annotation_r1 Evidence Notes

## Defect
- Defect ID: round_map_user_location_annotation_r1
- User-visible failure: Home map did not show the user's current-location annotation, and the current-location control did not move the map camera after permission was authorized.
- Target files / line ranges: `workspace/ios/Features/Home/MemoryMapHomeView.swift:240-310`, `workspace/ios/Shared/LocationPermissionStore.swift:83-143`, `workspace/ios/Tests/LocationPermissionStoreTests.swift:1-36`.

## Code Axis
- Reviewer: Codex Verifier fresh session (separate from implementer; Author != Verifier).
- Result: PASS
- Evidence:
  - A1: `MemoryMapHomeView.swift:241-243` places `UserAnnotation()` inside `Map(position: $cameraPosition, selection: $selectedMapItemID) { ... }`.
  - A2: `MemoryMapHomeView.swift:306-310` wires `onShowCurrentLocation` to `locationPermissionStore.handleCurrentLocationTap()` and sets `cameraPosition = .userLocation(fallback: .automatic)` when the result is `.centerOnUser`.
  - A3: `LocationPermissionStore.swift` has no working-tree diff (`git diff -- workspace/ios/Shared/LocationPermissionStore.swift` produced no output; `git status --short` did not list this file as modified). Existing permission branching remains at `LocationPermissionStore.swift:126-142`: authorized returns `.centerOnUser`, notDetermined requests permission and returns `.requestSystemPermission`, denied/restricted sets recovery prompt and returns `.showRecoveryPrompt`.
  - A3 tests: `LocationPermissionStoreTests.swift:7-14` covers authorized -> `.centerOnUser`; `LocationPermissionStoreTests.swift:16-25` covers notDetermined -> `.requestSystemPermission` plus authorization request; `LocationPermissionStoreTests.swift:27-35` covers denied -> `.showRecoveryPrompt` plus `.denied` recovery state.
- Reject reason, if FAIL: N/A

## Runtime Axis
- Device/simulator: iPhone 17 Pro, iOS Simulator 26.4, arm64.
- Scenario: `xcodebuild test` result bundle at `workspace/ios/.deriveddata/r67/Test-R67.xcresult`; verifier inspected `xcresulttool get test-results summary` and `xcresulttool get test-results tests`.
- Result: PASS
- Screenshot/video/xcresult: `workspace/ios/.deriveddata/r67/Test-R67.xcresult`
  - xcresult summary: result `Passed`; total `260`; passed `242`; failed `0`; skipped `18`.
  - New test PASS entries:
    - `LocationPermissionStoreTests/test_handleCurrentLocationTap_requests_when_not_determined()` result `Passed`.
    - `LocationPermissionStoreTests/test_handleCurrentLocationTap_returns_centerOnUser_when_authorized()` result `Passed`.
    - `LocationPermissionStoreTests/test_handleCurrentLocationTap_shows_recovery_when_denied()` result `Passed`.
- Reject reason, if FAIL: N/A

## Process Axis
- Contract locked: yes. `context_harness/operator/locks/round_map_user_location_annotation_r1.lock` exists and records `status: active`; lock event infra also exists and is excluded from whitelist scope per R63/R64/R65/R66 precedent.
- Acceptance count <= 3: yes. `acceptance.md` has exactly A1, A2, A3.
- Author != verifier: yes. `eval_protocol.md:4-6` declares Author as Codex Implementer fresh session (dispatch-1) and Verifier as separate Codex Verifier fresh session (dispatch-2); this evidence was produced in a fresh verifier session.
- Result: PASS
- Reject reason, if FAIL: N/A

## Handoff
- 3-axis verdict:

| Axis | Result |
|------|--------|
| Code | PASS |
| Runtime | PASS |
| Process | PASS |

- Commit/push delegated to Claude Code: yes
- OK to handoff.
