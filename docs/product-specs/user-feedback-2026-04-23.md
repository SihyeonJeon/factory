# User Feedback — 2026-04-23 (실기기 테스트 세션)

**출처:** 사용자 실기기 테스트 중 구두 피드백 (login01930193@gmail.com의 Unfading 테스트 세션).
**권위 있는 디자인 소스:** `docs/design-docs/Unfading Prototype.html` (이것을 layout 진실로 사용).

14개 항목, 우선순위·스트림 분류 포함.

---

## S-BACKEND — 즉시 수정 필요

### F12. 추억 저장 시 "infinite recursion detected in policy for relation 'group_members'" 🛑 블로커
- 원인: R15의 `group_members_select` 정책이 `group_members` 를 subquery로 참조 → RLS 재귀 트리거. `memories_insert` WITH CHECK의 `EXISTS(SELECT FROM group_members ...)`도 같은 경로를 타서 infinite recursion.
- 수정: `public.current_user_group_ids()` SECURITY DEFINER 헬퍼로 RLS 우회 서브쿼리 제공, 재귀 정책들을 헬퍼 기반으로 재작성.

### F11-서버. "이벤트" 계층 추가
- 데이터 모델: `public.events(id, group_id, title, start_date, end_date, is_multi_day, created_at)` 이미 존재. `memories.event_id` FK도 존재.
- 필요: 저장 시 "현재 시각을 포함하는 event 없으면 event 이름 입력받기 + is_multi_day 토글", 저장 RPC.

### F9-서버. 월별 지출 RPC
- `monthly_expense(p_group_id uuid, p_year int, p_month int) returns int` — `memories.cost` 합계

### F10-서버. 참여자 기록
- 추가 컬럼 `memories.participant_user_ids uuid[] not null default '{}'::uuid[]` — 모임 모드에서 참여자 subset.

### F2-서버. 미래 이벤트 + 알람
- `events.reminder_at timestamptz` 추가 → 클라이언트 UNUserNotification 스케줄.

### F2-서버. 한국 표준시 (KST) 일관
- DB는 tstz로 UTC 저장, 클라이언트는 표시·입력 KST. 백엔드 변경 없음, 클라이언트 작업.

---

## S-SHEET — Map/Sheet/Layout 디자인 충실도

### F1. Sheet 드래그 애니메이션이 어색 · 놓음 위치에서 가장 가까운 snap으로 부드럽게 이동하지 않음
- 현재: 드래그 중 value binding이 rubber-band 없이 튐. release 시 가장 가까운 snap으로 animated transition 없음.
- 대안: `.gesture(DragGesture())` + `@GestureState` + release 시 velocity 기반 nearest-snap 판정, `.interpolatingSpring` 또는 `cubicBezier(0.32, 0.72, 0, 1)` 340ms로 이동.

### F2-UI. 최대화 시 완전 일체화
- Prototype: `SHEET_STATES.expanded = 1.0`; expanded일 때 `borderTopRadius: 0`, `boxShadow: 'none'`.
- 현재: 88% stop + 라운드 유지. Prototype 위반.
- 수정: snap 세트 `{ collapsed: 0.085, default: 0.52, expanded: 1.0 }` 로 변경 + expanded일 때 `cornerRadius: 0`, 그림자 제거.

### F13. 메인 화면 상단 "추억 지도" 타이틀 제거, 아래 콘텐츠 위로 당기기
- Prototype엔 그 문자열이 없음 (TopChrome = 그룹 pill + 검색만).
- 수정: `MemoryMapHomeView` 에서 navigation/title 제거, TopChrome 하나만.

### F14. 나머지 레이아웃은 Prototype 그대로
- `TopChrome top: 54`, `FilterChipBar top: 108`, `FAB` `bottom: calc(var(--sheet-height) + 18px)`, `MapControls` 위 88px 등의 정확한 offset 준수.

---

## S-COMPOSER — 추억 만들기 화면 전수 개편

### F3. 장소 이름 입력 시 자동 지오코딩 복구
- 과거 작동하던 기능 회귀. `MKLocalSearch` 나 자체 자동완성으로 이름 → 좌표 매핑.

### F5. "근처 장소" 리스트 오동작
- 현재 샘플/더미/부정확한 결과. `MKLocalSearch`로 반경 지정 `MKLocalSearch.Request(pointOfInterestFilter: .includingAll, region: currentRegion(500m))`.

### F6. 첫 사진의 EXIF metadata 기반 자동 초기값
- `PHAsset.creationDate` → timestamp
- `PHAsset.location` → coordinate
- 위 값들을 composer 초기 state에 채워 넣기.

### F7. 사진 좌표 → 가장 가까운 place name 자동 매칭 + "이 위치가 아닌가요?" 수정 경로
- 역지오코딩(`CLGeocoder.reverseGeocodeLocation`) + POI 매칭(`MKLocalSearch` 반경 100m top-1).
- "이 위치가 아닌가요?" 탭 → 지도에서 직접 찍기 · 이름 검색 · "현재 위치 사용".

### F8. 메모·감정·카테고리·지출 모두 선택사항
- 현재 필수화된 필드 체크 제거. 저장 시 빈 값 허용.

### F11-UI. Date/Event 계층
- 저장 시 composer가 해당 date의 event를 fetch:
  - 존재: event 연결하여 save, Composer에 "이 이벤트에 추가" 배너.
  - 없음: "어떤 데이트/모임인가요?" 이름 필드 + "여행 (여러 날)" 토글. 여러 날 토글 on 시 start/end date picker.
- 저장은 create_event_if_missing RPC 또는 클라이언트 2-step (event insert → memory insert with event_id).

### F10-UI. 모임 모드 참여자 선택
- `groupStore.memberProfiles` 에서 multi-select, 저장 시 `participant_user_ids` 에 채움.
- 커플 모드는 필드 자체 숨김 (자동 = 전체 그룹 멤버).

### F4. 위치 권한 요청 on-launch
- 현재: `LocationPermissionStore`에 있지만 첫 실행 시 요청 flow가 안 걸려 있음.
- 수정: `MemoryMapApp.init` 또는 `RootTabView.task` 에서 첫 실행 시 요청.

---

## S-CALENDAR — 캘린더 기능 확장

### F9-UI. 월 지출 총액 표시
- 상단 헤더에 "이 달 지출: ₩X" 표시.

### F2-UI. 미래 계획 vs 과거 추억 구분
- 과거 날짜 cell: 기존 memory dot
- 미래 날짜 cell: "계획" 배지 (다른 색) — events.start_date 기준
- "계획 추가" CTA + 이벤트 date 선택 + 알람(UNUserNotification) 스케줄.
- 명칭: 미래는 "이벤트"/"계획", 과거는 "추억".

### F2-UI. KST
- 모든 `DateFormatter`에 `timeZone = TimeZone(identifier: "Asia/Seoul")` 강제.

---

## 스트림 분할 (병렬 Codex 위임 계획)

| Stream | 범위 | 의존 | Codex dispatch |
|---|---|---|---|
| **0 (ops)** | 백엔드 migration: F12 RLS fix, F11-server event RPC, F9 monthly_expense, F10 participants 컬럼, F2 reminder_at | — | 운영자 직접 SQL (MCP) |
| **A** | F1 sheet drag+snap, F2-UI 일체화, F13 title 제거, F14 prototype 레이아웃 세부 | S0 무관 | 1회 |
| **B** | F3 geocode, F5 근처장소, F6 EXIF, F7 매칭+대안, F4 위치권한 | S0 무관 | 1회 |
| **C** | F11-UI event 계층, F10-UI 참여자, F8 옵션화, F9-UI 월지출, F2-UI 계획vs추억 + KST | S0 선행 | 1회 (S0 이후) |

S0는 운영자가 5–10분 안에 끝. A·B는 병렬 바로 시작, C는 S0 직후 시작.

---

## 성공 기준

- [ ] 테스터 계정으로 추억 저장이 에러 없이 동작 (F12)
- [ ] Sheet drag snapshot이 Prototype 3-state에 스프링으로 부드럽게 snap (F1, F2)
- [ ] Expanded sheet가 화면과 완전 일체화 (radius 0, shadow 0) (F2)
- [ ] 메인 화면에 "추억 지도" 텍스트 없음 (F13)
- [ ] 위치 권한 다이얼로그가 앱 첫 실행 즉시 뜸 (F4)
- [ ] 장소 이름 입력 → 자동완성 + 좌표 반영 (F3)
- [ ] 사진 선택 시 첫 사진의 EXIF 로 시각·좌표 자동 채움 + 매칭 place 이름 표시 (F6, F7)
- [ ] "이 위치가 아닌가요?" 시트: 지도 선택 / 이름 검색 / 현재 위치 (F7)
- [ ] 메모·감정·카테고리·지출 빈 값 허용 저장 (F8)
- [ ] 모임 모드에서 참여자 multi-select + 저장 시 반영 (F10)
- [ ] 이벤트 없을 때 이름 입력 + "여행" 토글 on 시 여러 날 선택 (F11)
- [ ] 캘린더 헤더에 월 지출 총액 (F9)
- [ ] 미래 날짜 cell이 "추억" 대신 "계획" 표지 + 알람 스케줄 가능 (F2-calendar)
- [ ] 모든 시간 표시가 KST (F2)
