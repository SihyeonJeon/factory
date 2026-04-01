# Triad Multi-Agent Factory Rules (2026-04-01)

이 문서는 `workspace/` 내 에이전트들의 행동 규율(Constitution)이다.

---

## 1. Multi-Agent Orchestration

### 모델 라우팅 원칙
- **Claude Opus**: 아키텍처 설계, PRD 생성, 코드 리뷰, 교착상태 중재 (높은 추론 필요)
- **Claude Sonnet**: UI 컴포넌트 코딩, 비즈니스 로직, 버그 수정, 테스트 생성 (속도/품질 밸런스)
- **Claude Haiku**: 문서 생성, 보일러플레이트, 단순 파일 조작 (빠르고 저렴)
- **Gemini 2.5 Pro**: 시장 조사(웹 그라운딩), 시각적 QA(멀티모달 비전)
- **Gemini 2.5 Flash**: 스프린트 계약 평가, 빠른 체크리스트 검증
- **Codex (GPT)**: 코드 리뷰(`codex exec review`), 병렬 컴포넌트 코딩

### 에이전트 간 통신
- **Blackboard 패턴**: `context_harness/blackboard.md`에 모든 에이전트 활동 기록
- 각 에이전트는 작업 전 블랙보드의 최근 컨텍스트를 읽고, 완료 후 결과 요약을 기록
- 에이전트 간 직접 통신 없음 — 블랙보드를 통한 비동기 협업

### Fallback 체인
- 1차 모델 Rate Limit → 대기 후 재시도 (최대 2회)
- 재시도 소진 → 동일 Task의 Fallback 모델로 전환
- 모든 Fallback 소진 → 파이프라인 중단 + 사용자 알림

---

## 2. 바이브 코딩 품질 규율

### 상태 관리
- **Zustand 전역 상태 강제**: `store/` 디렉토리에 도메인별 store 정의
- `useState` 사용 조건: 해당 컴포넌트에서만 사용되고, 다른 컴포넌트와 공유할 가능성이 0%일 때만
- 스토어 구조를 아키텍트가 먼저 정의 → 코더는 이를 구독만

### 스타일링
- **NativeWind + Design Token 강제**: `theme.ts`에 색상/간격/타이포 정의
- 매직 넘버 절대 금지 (하드코딩된 px, 색상 헥스코드)
- 인라인 스타일 금지 — className prop만 사용

### 렌더링 퍼포먼스
- useEffect 의존성 배열 최소화
- React Compiler 또는 명시적 memo/useCallback 사용
- Reanimated: UI 스레드에서만 애니메이션 (worklet)

---

## 3. Apple HIG 엄수 (iOS 1차 타겟)

- **터치 타겟**: 탭 가능 요소 최소 44x44pt
- **SafeAreaView**: 모든 스크린의 최상위 뷰에 적용
- **다이내믹 아일랜드/노치**: 상단 침범 금지
- **네이티브 내비게이션**: 뒤로 가기 제스처, 모달 스와이프 보존 (커스텀 트랜지션 자제)
- **다크 모드**: OS 레벨 스위칭에 실시간 반응

---

## 4. 기술 스택 (고정)

| 카테고리 | 기술 | 이유 |
|----------|------|------|
| App Framework | Expo (SDK 52+) | AI 대응성 최고, Fastlane 연동 |
| Routing | Expo Router | 파일 기반, 웹 이식성 |
| Styling | NativeWind (TailwindCSS) | 클래스 기반 토큰, 토큰 효율 |
| State | Zustand | 보일러플레이트 최소, AI 친화 |
| Animation | Reanimated | 60/120fps UI 스레드 |
| Bottom Sheet | @gorhom/bottom-sheet | Reanimated 기반 |
| Maps | react-native-maps + clustering | 네이티브 맵 |

---

## 5. 스프린트 계약 기반 평가

- Phase 1에서 PRD 생성 시 `sprint_contract.json` 자동 생성
- 각 Epic의 수용 기준(Acceptance Criteria)이 P0/P1/P2로 우선순위화
- Phase 3 QA에서:
  1. Playwright E2E 테스트 (기본 렌더링/인터랙션)
  2. Gemini Vision 시각적 분석 (HIG 준수, 레이아웃 무결성)
  3. 스프린트 계약 평가 (Gemini Flash — 각 수용 기준별 PASS/FAIL)
- P0 기준 전체 통과 시에만 QA_PASS
