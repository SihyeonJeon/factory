# Multi-Agent Architecture — v4 (Role Restructure + Process Quality)

**Date:** 2026-04-14
**Status:** Active
**Reference:** Claude Code source leak analysis (2026-03-31)

---

## 1. Agent Roles & Execution Flow

### Role Assignment

```
Claude (Strategist)       → 전반적 계획 수립, 인간 승인 중재
Codex (Planner/Verifier)  → 세부 설계, 1차 검증 + 수정 지시
Claude Code (Implementer) → 코드 구현, 2차 검증 (교차 확인, 머지 판단)
```

### Co-Planning
- Claude + Codex: 공동 세부 계획 수립 (Codex 주도, Claude 검토)
- 모호한 구현 계획 → 인간에게 질문

### Flow (Anti-Self-Overestimation)

```
1. Claude: 전반적 계획 수립 + 인간 승인 대기
     ↓ (승인 후)
2. Codex + Claude Code: 공동 세부 계획/설계
     ↓
3. Claude Code: 코드 구현 (세부 사양 기반, 병렬 실행 가능)
     ↓
4. Codex: 1차 검증 (코드 리뷰, 테스트, 아키텍처 드리프트, 수정 지시)
     ↓ (문제 → 3번 반복)
5. Claude Code: 2차 교차 검증 (다른 관점, 품질 게이트, 머지 판단)
     ↓
6. Merge + 프로세스 기록 + SESSION_RESUME 갱신
```

**Rule: 작성자 ≠ 검증자.** Self-approval 절대 금지.
**Rule: 코드 작성 = Claude Code, 1차 검증 = Codex, 2차 검증 = Claude Code.**
서로 다른 관점을 제시하여 더 나은 방향 결정.

---

## 2. Context Management — 3-Layer Memory (Claude Code Pattern)

### Layer 1: 인덱스 (항상 로드)
- **CLAUDE.md** — 목차/포인터만. ~150자/줄. 실제 내용 없음.
- **MEMORY.md** — 사용자 메모리 인덱스 (auto-memory 시스템)
- **SESSION_RESUME.md** — 현재 상태 스냅샷

### Layer 2: 토픽 파일 (필요 시 조회)
- `docs/design-docs/` — 아키텍처, 멀티에이전트 구조
- `docs/product-specs/` — 수용 기준, HF 상태
- `docs/references/` — Supabase 스키마, API 참조
- `docs/exec-plans/` — 스프린트 이력, 메트릭스
- `SECURITY.md` — 보안 규칙
- `SKILLS.md` — 검증된 패턴 (모든 에이전트 공유)

### Layer 3: 트랜스크립트 (grep-only, 직접 로드 금지)
- `context_harness/handoffs/` — 스프린트 브리프 (완료 후 아카이브)
- `context_harness/reports/` — 평가 리포트 (verdict만 인덱싱)
- `context_harness/blackboard.md` — 최근 5건 append-only 로그

### Write Discipline (Claude Code Pattern)
1. 토픽 파일에 먼저 작성
2. 그 다음 인덱스(CLAUDE.md)에 포인터 추가
3. 인덱스에 직접 내용 절대 덤프 금지
4. 코드베이스에서 직접 유도 가능한 정보는 저장하지 않음

---

## 3. Stable/Dynamic Prompt Boundary (Claude Code Pattern)

### Stable Section (캐시 가능, 거의 변경 없음)
- 에이전트 역할 정의
- 품질 게이트 (44pt, Dynamic Type, VoiceOver, Korean, UnfadingTheme)
- 도구 제약 (code changes → dispatch only)
- 보안 규칙

### Dynamic Section (매 턴 갱신)
- 현재 brief 내용
- 최근 blackboard 엔트리 (5건)
- 평가 아티팩트 경로
- git status 스냅샷

**Cache-break 방지 규칙:**
- Stable section 변경 시 반드시 `[CACHE-BREAK]` 주석 + 이유 기록
- Dynamic section만 자유롭게 갱신 가능
- 평가 리포트 전문은 dynamic section에 넣지 않음 (verdict + blocker만)

---

## 4. Append-Only Process Logging

### 위치: `docs/exec-plans/process-log.jsonl`

모든 에이전트 활동을 append-only로 기록:

```jsonl
{"ts":"2026-04-14T10:19:47Z","agent":"codex","role":"ios_logic_builder","task":"sprint13","action":"implement","files_changed":8,"tests":79,"result":"success"}
{"ts":"2026-04-14T10:22:08Z","agent":"claude","role":"evaluator","task":"sprint11_eval","action":"evaluate","verdict":"PASS","blockers":0,"advisories":2}
{"ts":"2026-04-14T11:04:00Z","agent":"claude","role":"evaluator","task":"sprint12-14_eval","action":"evaluate","verdict":"BLOCKED","blockers":["B-1","B-2"]}
{"ts":"2026-04-14T11:30:00Z","agent":"codex","role":"ios_logic_builder","task":"remediation_B1_B2","action":"remediate","tests":79,"result":"success"}
```

### 회고 (Retrospective) 용도
- 실패 시: process-log.jsonl에서 해당 시점 앞뒤 기록 조회
- 어느 에이전트의 어느 단계에서 문제가 발생했는지 추적
- 에이전트 간 결정 경로 재구성 가능

---

## 5. Verify-Before-Use Pattern (Claude Code Pattern)

메모리/SKILLS에서 참조한 정보는 **반드시 현재 상태와 교차 검증**:

1. 파일 경로 → 파일 존재 확인
2. 함수/플래그 이름 → grep으로 존재 확인
3. 아키텍처 패턴 → 현재 코드와 일치 확인
4. 과거 평가 결과 → 재평가로 확인

"메모리는 힌트, 진실이 아니다. 사용 전에 검증한다."

---

## 6. Subagent Execution Models

### Fork (병렬 독립 작업)
- 부모 컨텍스트를 byte-identical 복제
- 5개 에이전트 포크 비용 ≈ 1개 비용 (캐시 공유)
- 평가 3종 병렬 실행에 적합

### Worktree (저장소 격리)
- git worktree를 통한 완전 격리
- 실험적/위험한 변경에 적합
- 현재 `.worktrees/_integration` 사용 중

### Sequential (순차 의존)
- 이전 결과에 의존하는 작업
- Sprint → Evaluation → Remediation 체인

---

## 7. Evaluation Architecture

### 결과물 품질 (Output Quality)

#### Gate 1: 자동 테스트
```
xcodegen generate && xcodebuild test
```
- 79+ 테스트 통과 필수
- 실패 시 즉시 중단

#### Gate 2: 3-Evaluator Cross-Review
| Evaluator | Model | Focus |
|-----------|-------|-------|
| red_team_reviewer | opus | 보안, 회귀, 아키텍처 |
| hig_guardian | sonnet | HIG, Dynamic Type, VoiceOver, 44pt |
| visual_qa | sonnet | 스크린샷, 레이아웃, 시각적 회귀 |

#### Gate 3: Cross-Agreement
- 2+ evaluator가 동일 파일 지적 → 필수 수정
- 1 evaluator만 지적 → 수정하되 불일치 기록

#### False-Positive 방어
- `extract_blockers()` regex 오탐 알려진 패턴
- 항상 리포트 본문 읽기 — boolean 신뢰 금지

### 프로세스 품질 (Process Quality)

결과물뿐 아니라 **그 결과물이 나오기까지의 프로세스도 평가**:

| 지표 | 측정 방법 | 기준 |
|------|----------|------|
| 리미디에이션 사이클 수 | process-log.jsonl에서 remediation 건수 | ≤2 per sprint |
| BLOCKER 재발률 | 동일 유형 BLOCKER 반복 여부 | 0 (SKILLS 등록 후) |
| 브리프 정확도 | 디스패치 실패율 (파일 누락, 모호한 사양) | ≤10% |
| 검증 교차율 | 1차/2차 검증자 간 불일치 발견 비율 | 기록 (높을수록 교차 효과 ↑) |
| SKILLS 활용률 | 관련 SKILL 참조 없이 진행한 디스패치 비율 | ≤5% |
| 드리프트 발견 시점 | 드리프트 발생 후 발견까지 스프린트 수 | ≤3 |

프로세스 품질이 떨어지면 → 하네스 구조/브리프 템플릿/SKILLS 개선

---

## 8. Code Drift Detection

매 3 스프린트마다:
1. `docs/design-docs/ios-architecture.md` 대비 현재 파일 구조 비교
2. `grep -r "\.system(size:"` → 하드코딩된 폰트 감지
3. `grep -rL "accessibilityLabel"` → a11y 누락 파일 감지
4. inline 색상 사용 감지 (UnfadingTheme 외)
5. 네이밍 컨벤션 드리프트 확인

---

## 9. Metrics Tracking

### `docs/exec-plans/metrics.jsonl`

```jsonl
{"session":"2026-04-14","sprint":"11-15","dispatches":8,"remediations":4,"tests":79,"blockers_found":2,"blockers_fixed":2,"advisory_fixed":5}
```

Track per session:
- 디스패치 수, 리미디에이션 수
- BLOCKER 발견→수정 사이클 수
- 테스트 수 진행
- 에이전트별 성공/실패율

---

## 10. SKILLS.md — Self-Improving Pattern Library

### 규칙
- 모든 에이전트는 작업 전 SKILLS.md 확인 필수
- 새 패턴 발견 시 즉시 기록 (검증 후)
- 3회 이상 적용된 패턴은 "검증됨" 태그
- 실패한 패턴도 기록 ("실패 사유" 포함)
- 상충하는 패턴 발견 시 → 인간에게 질문

### 자동 갱신 트리거
- 리미디에이션 사이클 발생 시
- 평가에서 새 BLOCKER 유형 발견 시
- 인간 피드백에서 반복 패턴 감지 시
