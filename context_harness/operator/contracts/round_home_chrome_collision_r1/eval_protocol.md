# Eval Protocol — round_home_chrome_collision_r1

## Author / Verifier
- Author: Codex Implementer fresh session.
- Verifier: 별도 Codex Verifier fresh session.
- Author ≠ Verifier.

## 3-Axis

### Code
- `MemoryMapHomeLayout` 의 신규 상수 + helper (line 인용).
- `MemoryMapHomeView.body` 의 topChrome / filterRow `.position(y:)` 가 helper 사용 (line 인용).

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r71`. xcresult 수치.
- 신규 단위 테스트 PASS.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope (R63-R70 precedent): source/test/contract/evidence valid; lock infra excluded.
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
