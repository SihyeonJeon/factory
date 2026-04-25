# Acceptance — round_verification_harness_three_axis_r1

라운드 close 는 다음 3개 acceptance 모두 충족 시.

## A1. 3축 PASS 의무 명문화
REGULATION_v5_9.md §C 가 다음을 명시:
- Verifier Codex 는 라운드 close 전 **별도 fresh session** 으로 작동.
- Code / Runtime / Process 3축 모두 PASS 만 close 허용.

**검증 방법**: REGULATION_v5_9.md §C 인용. 인용된 line 이 "fresh session", "all three axes PASS" 를 포함.

## A2. 1축 FAIL → REJECT + 재dispatch 명문화
REGULATION_v5_9.md §C 또는 §F 가 다음을 명시:
- Single-axis FAIL 시 라운드 reject.
- reject 사유는 `evidence/notes.md` 에 기록.
- 같은 round id 로 재dispatch (silent rollover 금지).

**검증 방법**: 인용된 line.

## A3. Commit/push handoff 명문화
REGULATION_v5_9.md §C 마지막 line 또는 §E (diagram) 가 다음을 명시:
- Code PASS + Runtime PASS + Process PASS 후에만 Claude Code 가 commit/push 수행.

**검증 방법**: 인용된 line.

## Verification axis tags
- 코드: 문서 grep / 인용.
- Runtime: N/A (이 라운드는 protocol infra). 첫 P0 round 에서 dry-run.
- Process: spec.md ↔ REGULATION_v5_9.md ↔ acceptance.md ↔ evidence/notes.md 일관.
