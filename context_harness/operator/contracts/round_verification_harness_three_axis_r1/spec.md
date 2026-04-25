# round_verification_harness_three_axis_r1 — Round close must require code, runtime, and process verification

## Purpose
- 60+ 라운드 후 결함이 누적된 원인은 넓은 brief, 큰 acceptance, 그리고 코드/실사용/프로세스 3축 검증 부재다. 목표는 모든 후속 라운드가 close 전 3축 PASS를 강제하도록 하네스 절차를 고정하는 것이다.

## Plan
- 수정 파일: `context_harness/operator/REGULATION_v5_9.md`; 검토 파일: `context_harness/operator/REGULATION.md`, `context_harness/operator/PROCESS_AUDIT_CHECKLIST.md`.
- 예상 변경 line 수: 120-180.
- 의존성: 없음.

## Acceptance (≤3)
1. Verifier Codex fresh session이 코드/실사용/프로세스 3축 모두 PASS하기 전 라운드 close 금지가 명문화된다.
2. 1축이라도 FAIL이면 같은 라운드를 재dispatch하고 reject 사유를 `evidence/notes.md`에 남기는 규칙이 명문화된다.
3. 3축 PASS 후에만 Claude Code가 commit/push를 수행한다는 handoff가 명문화된다.

## Verification (3축)
- 코드: 해당 없음. 문서 검증으로 `REGULATION_v5_9.md`의 MUST/FAIL/PASS 절을 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): 해당 없음. 대신 첫 P0 라운드에서 protocol dry run을 수행한다.
- 프로세스: `evidence/notes.md` 템플릿과 roadmap의 DAG가 이 protocol을 참조하는지 확인.

## Record
- `evidence/notes.md` 기록 항목: verifier session id, 3축 PASS/FAIL table, reject reason, commit handoff 여부.
