# Eval Protocol — round_map_pin_selection_stability_r1

## Author / Verifier
- Author: Codex Implementer fresh session (dispatch-1).
- Verifier: 별도 Codex Verifier fresh session (dispatch-2).
- Author ≠ Verifier.

## 3-Axis

### Code
- `PlacePickerSheet.swift:124-139` 의 `place = match.pickedPlace` 가 좌표 보존 형태로 변경됐는지 인용.
- `DiscoveredPlace` 에 helper (예: `pickedPlace(at:)`) 추가됐다면 인용.

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r66`. xcresult 수치 인용.
- 신규 회귀 테스트 PASS.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope: source/contract only (lock infra 제외, R63/R64 precedent).
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
