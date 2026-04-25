# Eval Protocol — round_button_placement_audit_r1

## Author / Verifier
- Author: Codex Implementer fresh session.
- Verifier: 별도 Codex Verifier fresh session.
- Author ≠ Verifier.

## 3-Axis

### Code
- `MemoryMapHomeLayout.HomeAction` 구조 + `homeActionInventory` 배열 (line 인용).
- category edit `+` 의 `.accessibilityHint(...)` 추가 (line 인용).
- inventory 의 identifier 가 코드 내 실제 identifier 와 일치 (cross-reference grep).

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r73`. xcresult 수치.
- 신규 inventory 단위 테스트 (≥4건) PASS.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope (R63-R72 precedent): source/test/contract/evidence valid; lock infra excluded.
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
