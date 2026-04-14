# Moment — 프로젝트 네비게이션

> 이 파일은 목차다. 세부 사항은 링크된 문서에서 펼쳐 읽는다.
> 에이전트는 전체를 로드하지 않고 관련 섹션만 on-demand로 조회한다.

## 세션 시작 절차 (필수)

매 세션 시작 시 아래 순서로 실행한다:

1. `CLAUDE.md` 읽기 (이 파일 — 인덱스만)
2. `SKILLS.md` 읽기 (검증된 패턴 — 같은 실수 반복 방지)
3. `git log --oneline -10` (최근 작업 파악)
4. `docs/product-specs/feature-registry.json` 읽기 (기능별 pass/fail 현황)
5. 작업 대상에 해당하는 문서만 펼쳐 읽기

> 전체 코드를 한꺼번에 읽지 않는다. 필요한 파일만 읽어 토큰을 아끼고 할루시네이션을 예방한다.

## 규칙 & 정책

| 문서 | 위치 | 읽는 시점 |
|------|------|----------|
| 보안 정책 | [SECURITY.md](SECURITY.md) | 코드 변경 시 |
| 검증된 패턴 | [SKILLS.md](SKILLS.md) | 매 세션 시작 시 |
| 하네스 헌법 | [context_harness/00_system_rules.md](context_harness/00_system_rules.md) | 역할/워크플로 확인 시 |
| 평가 기준표 | [docs/design-docs/evaluator-rubric.json](docs/design-docs/evaluator-rubric.json) | 평가 수행 시 |

## 설계 & 스펙 (`docs/`)

| 카테고리 | 경로 | 내용 |
|---------|------|------|
| 설계 문서 | `docs/design-docs/` | 아키텍처, 데이터 모델, 평가 rubric |
| 제품 스펙 | `docs/product-specs/` | PRD, 수용 기준, **feature-registry.json** |
| 실행 계획 | `docs/exec-plans/` | 스프린트 계획, 작업 분해 |
| 참고 자료 | `docs/references/` | 외부 API, Supabase 패턴 |
| 하네스 로그 | `docs/harness-logs/` | 라운드별 평가 결과, 회고 |

## 에이전트 워크플로

```
Human (의사결정, 모호성 해소, 세부 계획 승인)
  │
  ├─ Claude Code ── 전체 계획, 코드 구현, 2차 검증(교차확인+머지)
  │
  └─ Codex ──────── 세부 설계, 1차 검증+수정, 독립 관점
```

**핵심 원칙**:
- 구현한 에이전트 ≠ 검증 에이전트 (자기 과대 평가 방지)
- 모호한 계획 → 반드시 인간에게 질문
- 한 번에 하나의 기능만 작업 (포커스)
- 성공/실패 → 즉시 SKILLS.md 기록

## 기술 스택

- **Frontend**: Next.js 15 (App Router) + TypeScript strict + Tailwind
- **Backend**: Supabase (Auth, DB, Realtime, Storage, Edge Functions)
- **배포**: Vercel + PWA
- **타겟**: 한국 2030세대, 카카오톡 생태계

## 코드 컨벤션

- `web/` 작업 시 `web/AGENTS.md` 필수 참조
- API 엔드포인트: JSON try-catch → UUID 검증 → auth → 입력 검증 → 로직
- 한국어 에러 메시지, 내부 설정 노출 금지
- WCAG AA: 명암비 4.5:1+, 터치 44px+, reduced-motion, ARIA

## 빠른 참조

```bash
cd web && npm run dev          # 개발 서버
cd web && npx next build       # 빌드 검증
cd web && npx tsc --noEmit     # 타입 체크
cd web && npx supabase db push # 마이그레이션 적용
```
