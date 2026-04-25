# Eval Protocol — round_sheet_collapsed_tabbar_clearance_r1

## Author / Verifier
- Author: Codex Implementer fresh session.
- Verifier: 별도 Codex Verifier fresh session.
- Author ≠ Verifier.

## 3-Axis

### Code
- `UnfadingBottomSheet.swift` body 에 collapsed 8pt clearance 적용 (line 인용).
- `MemoryMapHomeView.swift` `sheetTopY` 가 동일 모델 사용 (line 인용).

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r69`. xcresult 수치.
- 신규 단위 테스트 PASS.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope: source/contract only.
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
