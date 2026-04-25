# Eval Protocol — round_tabbar_content_insets_r1

## Author / Verifier
- Author: Codex Implementer fresh session.
- Verifier: 별도 Codex Verifier fresh session.
- Author ≠ Verifier.

## 3-Axis

### Code
- `MemoryMapHomeLayout` 에 `tabBarReserve(safeBottom:)` helper 추가 (line 인용).
- `UnfadingTabShell.swift` 의 offlineQueueBanner overlay padding 이 helper 사용 (line 인용).
- non-map 탭 (calendar/settings) 에 `.safeAreaInset` 또는 padding 적용 (line 인용).

### Runtime
- `xcodebuild test -derivedDataPath .deriveddata/r70`. xcresult 수치.
- 신규 helper 단위 테스트 PASS.

### Process
- spec/acceptance/eval/file_whitelist 일관, acceptance ≤3.
- lock 존재.
- Whitelist scope: source/test/contract/evidence valid, lock infra excluded (R63-R69 precedent).
- Author ≠ Verifier 명시.

## Reject
- 1축 FAIL → REJECT + 동일 round id 재dispatch.
- 3축 PASS → Claude Code commit/push.
