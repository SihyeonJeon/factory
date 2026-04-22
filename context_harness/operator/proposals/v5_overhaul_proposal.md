# Harness v5 — Operator Peer Model (Proposal)

**Author:** Claude Code Operator
**Date:** 2026-04-19
**Status:** DRAFT — awaiting Codex Operator peer review (see `meetings/2026-04-19_v5_kickoff.md`)
**Trigger:** Deepsight 결과물(`docs/design-docs/travel_deepsight/`)로 8-screen Unfading 리디자인이 들어옴. 현재 v4 하네스는 교차 검증 규율과 컨텍스트 위생이 부족해 이 규모를 안전하게 처리하기 어려움.

---

## 1. Goals

1. Claude Code + Codex를 **principal/secondary**에서 **동등한 공동 운영자(co-operator)** 로 승격. 가벼운 결정은 회의로, 무거운 결정은 인간에게.
2. 모든 단계를 **교차(cross)**: 같은 단계 안에서 "생산자 = 검증자"가 되지 않도록 강제.
3. **컨텍스트 위생** 강제: 운영자는 짧은 페르소나 + File Index 만 항상 읽음. 나머지는 필요할 때만.
4. **규제 자체가 자기개선**: 라운드 종료 시 SKILLS/SECURITY 갱신이 머지 블록커.
5. **결과물뿐 아니라 프로세스**도 평가 (Gate 5 추가).

## 2. Persona & Context Layer

| File | 읽는 주체 | 상한 | 역할 |
|------|----------|-----:|------|
| `.claude/CLAUDE.md` | Claude Code Operator | 80줄 | 페르소나 + `operator/` 포인터 |
| `AGENTS.md` (repo root) | Codex Operator | 80줄 | 동일 구조 |
| `context_harness/operator/OPERATOR.md` | 두 운영자 공용 | 120줄 | 공통 페르소나, 의사결정 원칙 |
| `context_harness/operator/FILE_INDEX.md` | 두 운영자 공용 | 제한 없음 | 용도 → 파일 매핑 |

**규율:** FILE_INDEX 경유 없이 bulk read 금지. 필요할 때 `ls context_harness/`부터 찍는 습관을 버린다. FILE_INDEX에 없는 파일을 열려면 process-log에 사유 기록.

## 3. Stage Contract (교차 검증 매트릭스)

각 단계는 **Performer + Cross-Validator** 두 명. 같은 에이전트가 두 역할 겸임 금지.

| Stage | Performer | Cross-Validator | Artifact |
|-------|-----------|----------------|----------|
| Overall Planning | **Claude Code + Codex** (meeting) | Human | `operator/meetings/<round>_plan.md` |
| Detailed Design | Codex | Claude Code | `operator/contracts/<round>/spec.md` |
| Convention/Linter Lock | Claude Code | Codex | `operator/contracts/<round>/convention_version.txt` |
| Coding 1st pass | Claude Code | Codex (code + architecture review) | Commit + `meetings/<round>_review1.md` |
| Real-use evaluation | Codex | Claude Code | `context_harness/reports/<round>_eval.md` |
| Coding 2nd pass | **Codex + Claude Code** (meeting) | Human | Commit + retro |
| Round retro & regulation update | Both | Human | `operator/round_retro/<round>.md` + SKILLS/SECURITY diff |

**Gemini CLI 정책:** 기본 사용 안 함. (a) 초대형 컨텍스트 윈도우가 결정적으로 필요하거나 (b) Claude/Codex가 명시적으로 "Gemini가 더 낫다"고 합의할 때만 사용. 일반 루프에서 제외.

## 4. Regulation & Lock (멱등성/일관성)

### Per-round artifacts

```
operator/contracts/<round_id>/
├── spec.md                  ← 불변 입력 사양 (구현 중엔 수정 금지)
├── file_whitelist.txt       ← 쓰기 허용 파일 목록
├── convention_version.txt   ← 활성 coding-conventions.md SHA
├── lint_config.txt          ← 활성 린터 규칙
└── acceptance.md            ← 성공 기준
operator/locks/round_<N>.lock  (JSON: started_at, agents, hashes)
```

### Idempotency rules

- 단계 시작 시: lock 파일 검증 → spec/whitelist/convention 변경되었으면 **중단**, 먼저 meeting 열고 amendment 절차.
- 단계 중단 후 재개: lock의 started_at/agents 일치 확인.
- 같은 라운드 재실행이 이미 완료된 하위 단계를 깨지 않도록 mtime gate 유지 (feedback_idempotent_cache_guards).

## 5. Meeting Protocol

운영자 간 **회의 = 파일**. 대화가 아닌 **흔적 남는 협의**.

파일 템플릿 `operator/meetings/<ISO>_<topic>.md`:

```
# Meeting — <topic>

## Context  (3-5 bullets + 파일 포인터만; 인라인 복붙 금지)

## Proposal (Performer)  (명확한 입장 하나)

## Questions  (답변 가능한 구체 질문)

## Counter / Review  (Cross-Validator의 반론·대안·보완)

## Convergence  (반복 협의)

## Decision  (최종 결정 + 이유)

## Disagreement Recorded  (적어도 1건 — 없으면 할루시네이션 트립와이어)
```

**"적어도 한 번은 반론" 규칙**: 순수 사실 확인이 아닌 한, 교차 검증자가 반론 1건 이상을 기록해야 함. 없으면 회의 미완료. 이것이 자기 과대평가 방지의 핵심.

## 6. Process Audit — Gate 5

기존 Gate 1(빌드·테스트) / 2(3-evaluator) / 3(cross-agreement) / 4(process metrics)에 **Gate 5: Process Integrity** 추가. 라운드 종료 체크리스트:

- [ ] process-log.jsonl에서 이번 라운드 모든 결정 경로 재구성 가능
- [ ] 모든 commit이 라운드 lock에 매핑됨
- [ ] 모든 meeting에 "Disagreement Recorded" 섹션 채워짐
- [ ] SKILLS.md에 최소 1건 lesson 추가됨 (성공·실패 무관)
- [ ] 보안/사고 있었다면 SECURITY.md 갱신됨
- [ ] 새 파일 생겼다면 FILE_INDEX.md 갱신됨
- [ ] OPERATOR.md / STAGE_CONTRACT / REGULATION에서 발견된 불일치 있으면 amendment 제안됨

Gate 5 fail → 라운드 닫지 못함. 다음 라운드 시작 금지.

## 7. Self-Improving Regulation

라운드 종료 retro(`operator/round_retro/<round>.md`) 항목:

1. 이번 라운드에서 놓쳤던 것 (Performer 관점 1줄 + Cross-Validator 관점 1줄)
2. 반복되는 실수 → SKILLS 승격 후보
3. 하네스 규제 중 깨진 것 / 무용했던 것 → REGULATION amendment
4. 다음 라운드에 적용할 수정안 (있으면 별도 meeting 파일로 분리)

amendment도 meeting protocol 따름. 통과 시 `operator/CHANGELOG.md`에 기록 + `convention_version` 증가.

## 8. Context Discipline Rules

- CLAUDE.md/AGENTS.md ≤ 80줄 / OPERATOR.md ≤ 120줄 / FILE_INDEX.md ≤ 250줄
- Briefs ≤ 200줄 (기존)
- Blackboard 최근 5건 (기존)
- **읽기:** FILE_INDEX로 정확한 파일 지정. `ls <dir>` 탐색 금지.
- **쓰기:** 토픽 파일 먼저 → 그 다음 index 포인터. index에 내용 덤프 금지.

## 9. Migration Steps

1. `context_harness/operator/` 스캐폴드 (OPERATOR, FILE_INDEX, STAGE_CONTRACT, MEETING_PROTOCOL, REGULATION, PROCESS_AUDIT_CHECKLIST)
2. 루트 `AGENTS.md` 신설 (Codex Operator용)
3. `.claude/CLAUDE.md` 축소 (80줄) — 나머지는 operator/로 이관
4. 기존 `docs/design-docs/multi-agent-architecture.md` v4 문서 → v5로 업데이트 또는 포인터만 남기기
5. 이 제안서를 첫 meeting 안건으로 상정 → Codex peer review → 수렴 → 승인
6. 첫 라운드 계약 생성: deepsight 리디자인 처리 (`round_deepsight_r1`)
7. Round retro 템플릿 생성

## 10. Open Questions (for Codex peer review)

1. Gemini CLI를 team_manifest에서 완전 제거할지, tier-3 비상용으로 유지할지?
2. 회의를 markdown으로 할지 append-only JSONL로 할지? (나는 가독성 우선해 markdown 선호. 반론 환영)
3. "Disagreement must be recorded" 규칙이 순수 사실 확인 회의에 과할지, 항상 적용할지?
4. 평가 스크린샷 위치: `context_harness/reports/` 유지 vs `operator/` 하위 round-scoped로?
5. Codex에 design + 1st verify + real-use evaluation 세 역할이 몰림. 용량/레이턴시 괜찮은지, 재배치 필요한지?
6. 첫 라운드 작업 단위: 8-screen 리디자인을 한 번에 처리 vs 스크린 단위 슬라이싱? (design-revision-workflow.md Phase 3 대응)
7. 지금 v5 전환과 deepsight 처리를 병행할지, v5 정착 1 라운드 먼저 하고 deepsight은 그 다음 라운드로 미룰지?

---

## Appendix A — File tree after migration

```
factory/
├── AGENTS.md                                ← NEW (Codex persona)
├── .claude/CLAUDE.md                        ← SHRINK to ≤80 lines
├── SKILLS.md / SECURITY.md                   ← existing, now mandatory-append at round close
├── context_harness/
│   ├── SESSION_RESUME.md                    ← single source of truth (existing)
│   ├── operator/                            ← NEW
│   │   ├── OPERATOR.md
│   │   ├── FILE_INDEX.md
│   │   ├── STAGE_CONTRACT.md
│   │   ├── MEETING_PROTOCOL.md
│   │   ├── REGULATION.md
│   │   ├── PROCESS_AUDIT_CHECKLIST.md
│   │   ├── CHANGELOG.md
│   │   ├── contracts/<round_id>/
│   │   ├── locks/round_<N>.lock
│   │   ├── meetings/<ISO>_<topic>.md
│   │   ├── proposals/
│   │   └── round_retro/<round_id>.md
│   ├── handoffs/                             ← existing (sprint briefs)
│   └── reports/                              ← existing (evaluation artifacts)
└── docs/                                     ← existing
```
