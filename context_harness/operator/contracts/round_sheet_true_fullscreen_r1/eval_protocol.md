# Eval Protocol — round_sheet_true_fullscreen_r1

## Author / Verifier
- Author: Codex Implementer fresh session.
- Verifier: 별도 Codex Verifier fresh session.
- Author ≠ Verifier.

## 3-Axis

### Code
- `UnfadingBottomSheet.swift:151-223` 의 `availableHeight` 계산 / `ignoresSafeArea` 가 expanded 분기 적용 (line 인용).
- non-expanded 회귀 보존.

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r68`. xcresult 수치.
- 신규/회귀 테스트 PASS.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope: source/contract only (lock infra 제외).
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
