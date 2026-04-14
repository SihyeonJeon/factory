# 실행 계획: 하네스 v2 마이그레이션

> 기존 단일-모델 하네스 → Claude Code + Codex 듀얼 교차검증 하네스

## Phase 1: 기반 구조 (현재 세션)

- [x] `CLAUDE.md` — 프로젝트 네비게이션 목차
- [x] `SECURITY.md` — 프로젝트 보안 정책
- [x] `SKILLS.md` — 검증된 패턴 공용 지식
- [x] `docs/` 디렉토리 구조 생성
- [x] `docs/design-docs/harness-v2-architecture.md` — 새 아키텍처 설계
- [x] `docs/harness-logs/rounds-028-034-summary.md` — 기존 라운드 회고
- [x] `docs/product-specs/moment-mvp-acceptance.md` — 수용 기준

## Phase 2: 하네스 코드 개선

- [ ] `orchestrator.py` 리팩터링
  - [ ] 평가 입력을 high-signal로 축소 (diff 기반, 전체 코드 대신)
  - [ ] grader rubric 추가 (항목별 점수화)
  - [ ] 프로세스 품질 측정 메트릭 추가
  - [ ] 자동 검증 파이프라인 내장 (tsc, build, lint)
- [ ] `team_manifest.json` 업데이트
  - [ ] Codex 역할을 "1차 검증자"로 격상
  - [ ] Claude Code 역할을 "구현자 + 2차 검증자"로 명시
- [ ] 라운드 로그 자동 생성 (`docs/harness-logs/round-{N}.md`)

## Phase 3: 교차 검증 워크플로

- [ ] Codex 1차 검증 프롬프트 설계
  - 구현 diff + acceptance criteria + SECURITY.md → 리뷰 리포트
- [ ] Claude Code 2차 검증 프롬프트 설계
  - Codex 리뷰 + 원본 코드 → 교차 확인 + 머지 판단
- [ ] 의견 불일치 시 에스컬레이션 프로토콜

## Phase 4: 자동화

- [ ] CI/pre-commit에 보안 체크리스트 자동화
- [ ] 스크린샷 기반 UI 검증 통합
- [ ] 품질 추이 자동 차트 생성

## 의존성

```
Phase 1 (기반) → Phase 2 (코드) → Phase 3 (워크플로) → Phase 4 (자동화)
                                         ↑
                                    Human 검토 필요
                              (교차검증 프롬프트 승인)
```

## 리스크

| 리스크 | 대응 |
|-------|------|
| Codex와 Claude Code 간 컨텍스트 공유 한계 | repo 내 artifact (docs/, SKILLS.md)로 공유 |
| 교차 검증이 오히려 느려질 수 있음 | 병렬 실행으로 상쇄, 독립 작업은 동시 진행 |
| 두 모델의 관점이 동일할 수 있음 | 프롬프트에서 의도적으로 다른 관점 요청 |
