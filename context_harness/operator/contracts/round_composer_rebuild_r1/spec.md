# round_composer_rebuild_r1 — Composer 전면 재작성 (F8/F10/F11)

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only)
**Dependencies:** R26–R30 완료.

## Objective
Prototype 섹션 "6. Composer" 를 정확히 재현. F8 (전 필드 선택사항) / F10 (모임 참여자) / F11 (이벤트 계층 · 여행 토글) 를 이 라운드에서 흡수.

## Authoritative Source
`docs/design-docs/unfading_ref/design_handoff_unfading/README.md` 섹션 6.

## Acceptance

### 1. Composer 헤더
- `취소 / 새 추억 / 저장`.
- 저장 버튼은 **장소 confirmed 전에는 비활성** (chipBg + textTertiary).

### 2. 사진 그리드
- 3열. 첫 장은 2×2. 빈 슬롯은 대시 + 아이콘.
- Source row: 앨범 / 카메라 / 파일 (`SourceChip` 신규).
- "사진 메타데이터에서 가져온 정보" notice (accentSoft 배경, sparkle 아이콘, caption).

### 3. 장소 필드 (needs-confirm ↔ confirmed)
- `FieldRow` 신규 컴포넌트 — 상태별 스타일:
  - needs-confirm: `border 2px primary`, 우상단 `"확인 필요"` pill.
  - confirmed: `border 0.5px divider`, subdued.
- 아래 3개 `MiniButton` 수평:
  - `이 장소 맞아요` (primary) → state = confirmed.
  - `장소 변경` → 기존 PlacePickerSheet 재사용.
  - `현재 위치로` → CLLocationManager → closestMatch → confirmed.
- 저장 버튼 활성화는 `placeState == .confirmed` 일 때만.

### 4. 시간 — 24-hour WheelPicker
- `WheelPicker` 신규: 시 (0~23) + 분 (0~59) 두 휠, snap 모션.
- 초기값: 사진 EXIF seed 또는 Date().
- Font: meta Nunito Bold.

### 5. 이벤트 필드
- 기본 텍스트: `"같은 날 이벤트에 묶임 · 새 이벤트 만들기"`.
- 탭 → `EventFieldSheet` 신규:
  - 현재 날짜에 속한 event 자동 fetch (R15 `find_event_at`).
  - 있으면 "이 이벤트에 포함" 기본 선택.
  - 없으면 TextField "이벤트 이름" + `여행 (여러 날)` 토글.
  - 여행 토글 on → start/end DatePicker.
  - 저장 시 `create_event` RPC 호출 (R15) 후 memory 와 연결.

### 6. 참여자 필드 (general_group 전용)
- `groupStore.mode == .general` (mode == "group") 일 때만 렌더.
- 그룹 멤버 아바타 칩 목록, 기본값 **전원 체크**.
- 선택된 칩: `background member.color+'22'` + `border 1.5px member.color` + 체크 아이콘.
- `{N}/{총원}` 카운트.
- memory.participant_user_ids 에 반영 (R-feedback1 S0 에서 column 추가됨).

### 7. 한 줄 기록 (노트)
- TextField axis vertical, min-height 80pt, card background.
- **선택사항** (빈 값 허용).

### 8. 감정 태그 (7종)
- `설레임 / 따뜻함 / 행복 / 여유로움 / 즐거움 / 특별함 / 뭉클함` 7개 복수 선택 chip 목록.
- `UnfadingFilterChip` 재사용 (selectable).
- memory.emotions 에 한국어 ID 로 저장.
- **선택사항**.

### 9. 지출 (선택)
- `"₩ 금액 입력"` placeholder, numeric input.
- memory.cost 에 저장.
- **선택사항** (빈 값 = null).

### 10. 저장 플로우
- Place state != confirmed → 저장 disabled.
- 탭 → async 저장:
  1. (필요 시) create_event → eventId 획득
  2. 사진 업로드 (R20 PhotoUploader)
  3. DBMemoryInsert — event_id, participant_user_ids, emotions, cost 포함
  4. 성공 시 dismiss + MemoryStore upsert

### 11. F8 선택사항 재확인
- 노트·감정·카테고리·지출: 저장 시 빈 허용. 오직 **장소·시간·(사진 0장 이상)** 만 필수.
- 사진 0장 + 노트 0 + 감정 0 + 지출 0 도 저장 가능? → README 는 구체 명시 없음. 장소·시간 confirmed 이면 저장 허용. 사진 0장 시 "placeholder" 메모리 생성.

### 12. 재사용 자산
- 기존 `MemoryComposerSheet` / `MemoryComposerState` 대대적 재작성 (backward-compat 최소).
- 기존 `PlacePickerSheet` (R-feedback1) 재사용.
- 기존 `NearbyPlaceService` + `PhotoMetadataExtractor` 재사용.
- 기존 `PhotoUploader` + `RemoteImageView` 재사용.
- 신규: `FieldRow`, `MiniButton`, `WheelPicker`, `EventFieldSheet`, `SourceChip`, `ParticipantChip`.

### 13. UnfadingLocalized.Composer 확장
- 기존 키 유지.
- 신규:
  - `confirmLabel = "확인 필요"`
  - `confirmThisPlace = "이 장소 맞아요"`
  - `changePlace = "장소 변경"`
  - `useCurrent = "현재 위치로"`
  - `eventFieldTitle = "이벤트"`
  - `eventBindToSameDay = "같은 날 이벤트에 묶임"`
  - `eventCreateNew = "새 이벤트 만들기"`
  - `eventTripToggle = "여행 (여러 날)"`
  - `eventStartDate = "시작"`
  - `eventEndDate = "종료"`
  - `participantsFieldTitle = "이 추억의 참여자"`
  - `participantsAll = "전원 포함"`
  - `participantsCountFormat = "%d/%d명"`
  - `emotionSection = "감정 태그"`
  - `emotionJoy = "행복"`, `emotionCalm = "여유로움"`, `emotionThrill = "설레임"`, `emotionWarm = "따뜻함"`, `emotionFun = "즐거움"`, `emotionSpecial = "특별함"`, `emotionMoving = "뭉클함"`
  - `costPlaceholder = "₩ 금액 입력"`
  - `sourceAlbum = "앨범"`, `sourceCamera = "카메라"`, `sourceFile = "파일"`
  - `metadataSparkleNotice = "사진 메타데이터에서 가져온 정보"`

### 14. 테스트
- `MemoryComposerStateTests` 기존 유지 + 확장:
  - placeState = needs-confirm → save disabled.
  - confirmPlace → placeState = confirmed, save enabled.
  - emotions empty save OK.
  - mode == .couple 시 participants 필드 숨김.
  - mode == .general 시 기본 participants = 전원.
- 신규 `EventFieldSheetTests` — existing event 자동 선택 vs create 분기.
- 신규 `WheelPickerTests` — 값 범위 0~23, 0~59.
- UITest: `testComposerSaveDisabledUntilConfirmed`.

### 15. 아티팩트
- `contracts/round_composer_rebuild_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_composer_rebuild_plan.md` (Challenge Section)
- `reports/round_composer_rebuild_r1/evidence/notes.md`

### 16. 빌드·테스트
- `xcodegen generate`
- `xcodebuild test -derivedDataPath .deriveddata/r31` — 3회 재시도.

## Out of scope
- Memory Detail UI (R32).
- Calendar 계획 카드 (R33).
- Dark mode (R39).
- Category per-memory 필터 동작 (R38).

## 회귀 리스크
- 기존 MemoryComposerStateTests 호출 시그니처 변경.
- PhotoUploader 호출 경로 변경 가능.
- R-feedback1 에서 wired 된 photoSeed/applyPickedPlace 경로 보존.
