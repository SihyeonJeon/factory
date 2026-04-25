# Eval Protocol — round_verification_harness_three_axis_r1

본 라운드는 **infrastructure / documentation 라운드** 이므로 standard runtime eval 대신 protocol dry-run 으로 대체.

## Verifier session
- Author: orchestrator Codex (handoff session)
- Verifier: Codex 별도 fresh session (`codex_verifier_r62` 또는 후속).
- Author ≠ Verifier 강제.

## 3-axis verification

### Code axis
- Method: `rg` 또는 read 로 REGULATION_v5_9.md §C/§D/§E 내용 인용.
- Pass criteria: spec acceptance 1/2/3 각각 1개 이상의 정확한 인용 (line 번호 포함).

### Runtime axis
- Method: 본 라운드는 코드 변경 없음 → runtime axis 는 N/A.
- Replacement: 첫 P0 round 의 close cycle 이 본 protocol 을 실제 수행 → dry-run evidence 가 protocol soundness 입증.
- Pass criteria: `evidence/notes.md` Runtime 섹션 에 "deferred to first P0 round" 명시 + verifier acknowledge.

### Process axis
- Method:
  - spec.md 의 4 섹션 (Plan / Acceptance / Verification / Record) 형식 준수 확인.
  - acceptance.md 의 acceptance count ≤ 3.
  - file_whitelist.txt 가 본 라운드 산출물만 포함.
  - lock 파일 (`context_harness/operator/locks/round_verification_harness_three_axis_r1.lock`) 존재.
  - evidence/notes.md 가 REGULATION_v5_9 §D 템플릿 형식.
- Pass criteria: 위 5개 모두 PASS.

## Reject handling
- 1 axis FAIL → verifier 가 evidence/notes.md 에 reject reason 기록 + 동일 round id 로 재dispatch.
- 3-axis PASS → Claude Code 가 commit/push 권한 행사.

## Gate evidence
- `gate_evidence.json` 은 spec.md / REGULATION_v5_9.md / evidence/notes.md 의 SHA 와 verifier session id 만 기록 (코드 빌드 evidence 없음).
