# Eval Protocol — round_map_user_location_annotation_r1

## Author / Verifier
- Author: Codex Implementer fresh session (dispatch-1).
- Verifier: 별도 Codex Verifier fresh session (dispatch-2).
- Author ≠ Verifier.

## 3-Axis

### Code
- `MemoryMapHomeView.swift:240-275` 에 `UserAnnotation()` 또는 equivalent 추가됐는지.
- `mapControls.onShowCurrentLocation` 이 cameraPosition 갱신까지 연결됐는지 (line 인용).
- 권한 거부/제한 분기 보존 (regression).

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r67`. xcresult 수치.
- 신규 또는 기존 LocationPermissionStore 테스트 PASS 인용.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope: source/contract only (lock infra 제외).
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
