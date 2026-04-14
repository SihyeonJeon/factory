# SKILLS — 검증된 패턴과 실패한 패턴

> 모든 에이전트가 작업 전 참조하는 공용 지식 베이스.
> 성공하면 즉시 기록, 실패하면 즉시 기록. 가설이 아닌 검증된 사실만 기록한다.

---

## 성공한 패턴 (DO)

### S-001: 하네스 반복으로 품질 수렴
- **상황**: Moment MVP 코드 리뷰
- **방법**: Planner-Generator-Evaluator 3-agent 하네스를 28~34라운드 반복
- **결과**: CONDITIONAL_PASS(3M+4L) → 6라운드 만에 연속 PASS 달성
- **핵심**: 워크트리 지연(worktree lag)으로 이미 수정된 항목이 재보고됨 — 각 finding을 메인 브랜치 기준으로 교차검증 후 수정 여부 판단

### S-002: SECURITY DEFINER RPC에는 반드시 내부 인가 체크
- **상황**: `mark_participant_paid` RPC가 API 라우트에서만 호스트 검증
- **문제**: Supabase 클라이언트 SDK로 직접 RPC 호출하면 우회 가능
- **해결**: RPC 함수 내부에 `auth.uid() = events.host_id` 체크 추가
- **교훈**: API 라우트 인가 ≠ DB 레벨 인가. 둘 다 필요

### S-003: JSON try-catch 패턴으로 API 엔드포인트 강화
- **상황**: `await request.json()` 이 malformed body에서 unhandled exception
- **해결**: typed 변수 선언 + try-catch 래핑
- **주의**: `unknown` + `as` 캐스트 대신 명시적 타입 변수 사용 (TS 빌드 에러 방지)

### S-004: WCAG 명암비는 모든 무드 테마에 대해 검증
- **상황**: 6개 무드 중 5개가 흰 글씨 대비 WCAG AA 실패
- **해결**: primary 색상을 어둡게 조정 (4.5:1+ 확보)
- **교훈**: 색상 팔레트 추가/변경 시 즉시 명암비 계산

### S-005: OG 이미지에 한국어 폰트 명시 등록
- **상황**: `ImageResponse`에 폰트 미지정 → 한국어가 깨질 위험
- **해결**: Google Fonts에서 Noto Sans KR woff 가져와서 fonts 옵션에 등록
- **교훈**: 한국어 프로덕트에서 Satori/OG 이미지 생성 시 폰트 누락은 치명적

### S-006: SECURITY DEFINER 함수에는 `set search_path = ''` 필수
- **상황**: migration 00008의 RPC가 search_path 미고정
- **문제**: 세션 search_path 조작으로 다른 스키마의 동명 테이블 참조 가능
- **해결**: `set search_path = ''` 추가 + 모든 테이블을 `public.` 접두사로 완전 정규화
- **교훈**: SECURITY DEFINER 함수 작성 시 체크리스트: ① auth.uid() 검증 ② search_path 고정 ③ 테이블명 완전 정규화

### S-007: 클라이언트-서버 간 JSON 키 이름 일치 확인
- **상황**: 클라이언트에서 `eventId`, 서버에서 `event_id` 읽음 → 리마인더 기능 완전 고장
- **문제**: 같은 모델이 7라운드 검증해도 발견하지 못함 (자기 편향)
- **해결**: Codex 교차 검증으로 발견
- **교훈**: API 엔드포인트 추가 시 클라이언트 호출부와 서버 파싱부의 키 이름을 직접 대조

### S-008: 교차 검증은 자기 검증보다 실질적 결함을 더 많이 발견
- **상황**: Claude 자기 검증 7라운드 PASS → Codex가 5개 실질적 결함 추가 발견
- **교훈**: 구현한 모델 ≠ 검증 모델. 같은 모델은 같은 blind spot을 반복

### S-010: SW fetch handler에서 내부 catch가 에러를 소멸시키면 외부 catch 미도달
- **상황**: `fetchPromise.catch(() => cached)`가 에러를 흡수 → 외부 `.catch()`로 offline fallback 도달 불가
- **교훈**: Promise 체인에서 에러 전파 경로를 추적 — catch 내부에서 대안이 없으면 rethrow

### S-011: SW 캐시 저장 시 response.ok 체크 필수
- **상황**: 5xx/redirect 응답도 캐시에 저장 → 사용자에게 복구 불가능한 오류 페이지 반복 노출
- **해결**: `response.ok && response.type === "basic"` 가드

### S-012: Push notification data는 공격자 제어 입력
- **상황**: `notificationclick` 핸들러가 `event.notification.data.url`을 검증 없이 `openWindow()`에 전달
- **해결**: `new URL()` 파싱 + same-origin 검증, pathname 기반 매칭

### S-013: 서버 입력 검증 시 trim 후 길이 체크
- **상황**: PATCH /api/events/[id] 에서 whitespace-only 제목이 통과
- **해결**: `body.title.trim()` 후 길이 검증
- **교훈**: 모든 텍스트 입력은 trim → 빈값 체크 → 길이 체크 순서

### S-014: Boolean 파라미터도 typeof 체크
- **상황**: `hasFee: "true"` 가 `=== true` 비교로 false로 변환됨 (의도와 다른 결과)
- **해결**: `typeof body.hasFee !== "boolean"` 이면 400 반환
- **교훈**: 암묵적 coercion에 의존하지 말고 타입을 명시적으로 검증

### S-015: 커버 이미지는 이벤트 생성 후 서버 사이드로 업로드
- **상황**: 클라이언트가 `covers/<uuid>` 경로로 Storage 직접 업로드 → RLS 패턴 `{event_id}/{user_id}/...` 불일치
- **추가 문제**: 이벤트 생성 전이므로 event_id가 없음
- **해결**: FormData로 API에 파일 전송 → 이벤트 생성 후 올바른 경로로 서버 업로드
- **교훈**: Storage RLS가 경로 기반일 때, 업로드 경로가 정책과 일치하는지 반드시 검증

### S-016: 정산 create는 upsert가 아닌 insert — 기존 납부 상태 보호
- **상황**: 정산 재생성 시 upsert로 모든 납부 상태가 초기화됨
- **해결**: 기존 정산 존재 시 409 Conflict 반환
- **교훈**: upsert는 "마지막 쓰기 승리" — 상태가 있는 데이터에는 사용 금지

### S-009: 기존 마이그레이션 수정 금지 — 새 파일로 생성
- **상황**: migration 00007 수정 후 되돌리고 00008 새로 생성
- **교훈**: 이미 적용된 마이그레이션은 절대 수정하지 않음. `CREATE OR REPLACE`로 새 마이그레이션 추가

---

## 실패한 패턴 (DON'T)

### F-004: 동일 모델 자기 검증으로 7라운드 PASS 받았으나 5개 실질적 결함 존재
- **상황**: Claude가 구현+검증 모두 수행, Round 33-34에서 연속 PASS
- **실제**: Codex 교차 검증으로 리마인더 완전 고장, search_path 미고정 등 발견
- **교훈**: PASS는 "검증자의 blind spot 내에서 통과"일 뿐. 다른 관점 필수

### F-001: 평가 프로세스를 인자 없이 호출
- **상황**: `run_evaluation()` 시그니처가 `brief` 필수 인자로 변경됨
- **증상**: 프로세스가 시작 후 즉시 종료, journal에 기록 없음
- **교훈**: orchestrator API 변경 시 호출부도 반드시 업데이트

### F-002: 자기가 구현한 코드를 자기가 검증
- **상황**: Generator가 자체 코드 리뷰 → 자기 과대 평가로 결함 누락
- **교훈**: 구현 에이전트 ≠ 검증 에이전트. 반드시 교차 검증

### F-003: 커버 이미지 URL regex가 기본 커버 차단
- **상황**: `[a-f0-9-]+` 패턴이 `birthday.svg` 같은 이름 거부
- **교훈**: 검증 regex 작성 시 모든 유효 입력 케이스를 열거하고 테스트

---

## 워크플로 패턴

### W-001: 하네스 라운드 실행 절차
```
1. run_evaluation(brief) 실행 (백그라운드)
2. operator_journal.md 마지막 줄로 완료 확인
3. code_review.md + ux_audit.md 읽기
4. 워크트리 지연 여부 교차검증 (메인 브랜치 기준)
5. 신규 finding만 수정 + 빌드 검증
6. 커밋 → 다음 라운드
```

### W-002: 커밋 메시지 패턴
```
fix: resolve Round {N} review findings ({finding-ids})

{각 finding별 한 줄 설명}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```
