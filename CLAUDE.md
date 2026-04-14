# Moment — 프로젝트 네비게이션

> 이 파일은 목차다. 세부 사항은 링크된 문서에서 읽는다.
> 에이전트는 작업 시작 전 관련 섹션만 펼쳐 읽고, 전체를 로드하지 않는다.

## 아키텍처 & 규칙

| 문서 | 위치 | 용도 |
|------|------|------|
| 보안 정책 | [SECURITY.md](SECURITY.md) | RLS, 인증, 입력 검증, 비밀 관리 — 모든 코드 변경 시 참조 필수 |
| 하네스 헌법 | [context_harness/00_system_rules.md](context_harness/00_system_rules.md) | 에이전트 역할, 라우팅, 포크 정책 |
| 팀 매니페스트 | [context_harness/team_manifest.json](context_harness/team_manifest.json) | 역할-모델 매핑, 프로바이더 설정 |
| 검증된 패턴 | [SKILLS.md](SKILLS.md) | 에이전트 공용 — 성공한 패턴과 실패한 패턴 |

## 설계 문서 (`docs/`)

| 카테고리 | 경로 | 내용 |
|---------|------|------|
| 설계 문서 | `docs/design-docs/` | 아키텍처 결정, 데이터 모델, 시퀀스 다이어그램 |
| 제품 스펙 | `docs/product-specs/` | PRD, 수용 기준, 에픽 정의 |
| 실행 계획 | `docs/exec-plans/` | 스프린트 계획, 작업 분해, 의존성 그래프 |
| 참고 자료 | `docs/references/` | 외부 API, 카카오 가이드, Supabase 패턴 |
| 하네스 로그 | `docs/harness-logs/` | 라운드별 평가 결과, 회고, 품질 추이 |

## 에이전트 워크플로

```
Human (의사결정, 모호성 해소)
  │
  ├─ Claude Code ──── 전체 계획 수립, 코드 구현, 2차 검증(교차확인+머지 판단)
  │
  └─ Codex ────────── 세부 설계, 1차 검증+수정, 독립적 관점 제시
```

### 역할 분담

| 단계 | 담당 | 산출물 |
|------|------|--------|
| 계획 | Claude Code + Codex 공동 | exec-plan, acceptance criteria |
| 세부 설계 | Codex 선행 → Claude Code 검토 | design-doc |
| 구현 | Claude Code | 코드 커밋 |
| 1차 검증 | Codex | 리뷰 리포트 + 수정 패치 |
| 2차 검증 | Claude Code (교차확인) | 머지 판단, 최종 리포트 |
| 회고 | 양쪽 교차 | harness-log, SKILLS.md 업데이트 |

> **핵심 원칙**: 구현한 에이전트가 자기 코드를 검증하지 않는다.
> 모호한 구현 계획은 반드시 인간에게 질문한다.

## 기술 스택

- **Frontend**: Next.js 15 (App Router) + TypeScript strict + Tailwind
- **Backend**: Supabase (Auth, DB, Realtime, Storage, Edge Functions)
- **배포**: Vercel + PWA
- **타겟**: 한국 2030세대, 카카오톡 생태계 최적화

## 코드 컨벤션

- `web/` 디렉토리에서 작업 시 반드시 `web/AGENTS.md` 참조 (Next.js 버전 주의사항)
- 모든 API 엔드포인트: UUID 검증 → auth 체크 → 입력 검증 → 비즈니스 로직
- 한국어 에러 메시지 사용, 내부 설정 노출 금지
- WCAG AA: 명암비 4.5:1+, 터치 타겟 44px+, `prefers-reduced-motion` 존중

## 빠른 참조

```bash
# 개발 서버
cd web && npm run dev

# 빌드 검증
cd web && npx next build

# 마이그레이션 적용
cd web && npx supabase db push

# 하네스 평가 실행
python3 -c "from orchestrator import run_evaluation; run_evaluation('brief')"
```
