# Eval Protocol — round_tabbar_compact_height_r1

## Author / Verifier
- Author: Codex Implementer (fresh session, dispatch-1).
- Verifier: 별도 Codex Verifier (fresh session, dispatch-2).
- Author ≠ Verifier 강제.

## 3-Axis Verification

### Code axis
- Method: `UnfadingTabShell.swift` 의 `UnfadingTabBar.height` 값 / hit target frame / VStack alignment 인용 (line 번호 포함).
- Pass criteria: A1/A2/A3 코드 인용 충족.

### Runtime axis
- Method: `xcodebuild test -derivedDataPath .deriveddata/r65 -resultBundlePath .deriveddata/r65/Test-R65.xcresult`. xcresult passedTests/failedTests 인용.
- Pass criteria: 전체 테스트 PASS, 신규 (또는 기존) 회귀 테스트 PASS.

### Process axis
- spec.md / acceptance.md / eval_protocol.md / file_whitelist.txt 일관.
- lock 파일 (`context_harness/operator/locks/round_tabbar_compact_height_r1.lock`) 존재.
- Whitelist scope: source/contract artifacts only; lock infrastructure 제외 (R63 precedent).
- evidence/notes.md REGULATION_v5_9 §D 형식.

## Reject handling
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code 가 commit/push.
