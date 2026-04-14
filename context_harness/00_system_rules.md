# Harness Constitution v2

> 듀얼 에이전트 교차 검증 아키텍처.
> 상세 설계: `docs/design-docs/harness-v2-architecture.md`

## 1. 에이전트 역할

| 에이전트 | 역할 | 절대 하지 않는 것 |
|---------|------|-----------------|
| **Claude Code** | 전체 계획, 코드 구현, 2차 검증(교차확인+머지) | 자기가 구현한 코드를 1차 검증 |
| **Codex** | 세부 설계, 1차 검증+수정 패치, 독립 관점 제시 | 최종 머지 판단 |
| **Human** | 의사결정, 모호성 해소, 최종 승인 | — |

## 2. 워크플로

```
계획 → 병렬 구현 (에이전트 N개) → Layer 1 게이트 (tsc+build+playwright)
  → 커밋 → Layer 2 교차 검증 → 수정 → Layer 1 재실행 → 재커밋
  → Layer 4 Rubric 평가 (라운드 완료 시)
```

- 모호한 구현 계획 → Human에게 질문
- 의견 불일치 → Human 에스컬레이션
- 검증 통과 → 머지 + SKILLS.md 업데이트
- 새 기능 추가 시 E2E 테스트 동시 작성 (테스트 없는 기능은 미완료)

## 3. 컨텍스트 원칙 — High Signal

- 에이전트에게 전체 코드/히스토리를 주지 않는다
- 변경 diff + 관련 acceptance criteria + 빌드/테스트 결과만 제공
- 이전 라운드는 3줄 요약으로 압축
- blackboard는 현재 활성 결정사항만 유지

## 4. 검증 체계

### Layer 1: 자동 게이트 (구현 직후, 커밋 전)
- `npx tsc --noEmit` — 타입 체크
- `npx next build` — 빌드 검증
- `npx playwright test` — E2E 스모크 테스트 (smoke, auth, API, a11y, console)
- 3개 모두 통과해야 커밋 가능

### Layer 2: 교차 검증 에이전트 (커밋 후)
- 구현한 에이전트 ≠ 검증 에이전트 (Explore 또는 Codex)
- 전체 파일 리뷰: 보안/RLS/입력검증/키 일치/타입/경쟁조건/Next.js 15
- 발견사항: Critical/High/Medium/Low 분류 + 라인 번호 + 수정안
- Critical/High → 즉시 수정 → Layer 1 재실행 → 재커밋

### Layer 3: Playwright 회귀 테스트 (수정 후)
- 수정 사항이 기존 테스트를 깨뜨리지 않는지 확인
- 새 기능 추가 시 해당 기능의 E2E 테스트도 추가
- 테스트 위치: `web/e2e/`

### Layer 4: Rubric 평가 (라운드 완료 시)
- Grader rubric 기반 점수화: 보안/기능/접근성/성능/코드품질 각 0-10
- 프로세스 품질 측정: 커밋 명확성, 변경 범위, 테스트 커버리지
- Playwright 테스트 커버리지 + 통과율 반영

## 5. 산출물 위치

| 산출물 | 경로 |
|-------|------|
| 설계 문서 | `docs/design-docs/` |
| 수용 기준 | `docs/product-specs/` |
| 실행 계획 | `docs/exec-plans/` |
| 참고 자료 | `docs/references/` |
| 라운드 로그 | `docs/harness-logs/` |
| 검증 패턴 | `SKILLS.md` |
| 보안 정책 | `SECURITY.md` |

## 6. 릴리스 게이트

`docs/product-specs/moment-mvp-acceptance.md`의 모든 기준 충족 + 연속 2회 PASS 필요.

## 7. 운영 지식 관리

- 성공한 패턴 → 즉시 `SKILLS.md`에 기록
- 실패한 패턴 → 즉시 `SKILLS.md`에 기록
- 모든 에이전트는 작업 전 `SKILLS.md` 참조
- 워크플로는 패턴화하여 재사용 (`W-xxx`)
