# round_calendar_dial_r1 — Calendar 다이얼 네비 + 계획 카드 + 알림 (Sprint 29)

**Dependencies:** R26–R32.

## Authoritative Source
README 섹션 "7. Calendar" + "Sprint 22" (다이얼) + "Sprint 29" (계획/스왑).

## Acceptance

### 1. 월 다이얼 네비 (Sprint 22)
- Prototype 은 좌우 화살표 + 월 라벨로 단순화. SwiftUI 는 다음 중 하나:
  - `DatePicker(.wheel)` 을 **월** 단위로 구현 (iOS `.month` component only).
  - 또는 `Picker` 를 horizontal 로 스크롤.
- 기존 `CalendarView` 의 월 이동 chevron 버튼 유지하되, 상단 가운데에 **월 라벨 tap → Picker sheet open** 추가.
- Picker sheet: 12월 × N년 리스트, 현재 월 강조.

### 2. 요일 헤더
- Nunito 10.5/700 textSecondary. 현재 구현 유지.

### 3. 날짜 셀
- 44×44. 추억 있는 날에는 하단에 **3점 도트 (primary)**.
- 미래 날짜 + 계획 있으면 lavender 도트 (기존 R-feedback1 C2 유지).

### 4. Day Detail
- 날짜 타이틀 + **날씨** (샘플 맑음 아이콘, 실제 날씨 API 는 deferred).
- 이벤트 리스트 카드.
- **general_group 전용 계획 카드** (Sprint 29):
  - 민트 gradient 카드.
  - 타이틀: `"다음 만남 — {요일/날짜}"`.
  - 장소 + 시작 시각.
  - **RSVP 요약** (`✓ 3 · ? 1 · ✗ 0`).
  - 액션 row: `[계획 추가]` primary CTA + `[알림 보내기]` secondary.
  - 알림 보내기 → 바텀 토스트 `"모든 멤버에게 알림을 보냈어요"`.

### 5. RSVP 스토어 (신규)
- `workspace/ios/Features/Calendar/RSVPStore.swift`:
  - `@MainActor ObservableObject` + `@Published rsvps: [UUID: RSVPStatus]` (user_id → status).
  - Enum RSVPStatus: `.going, .maybe, .notGoing`.
  - 이번 라운드는 **클라이언트 @State only**. DB 저장은 R38 deferred.
  - `summary` computed: `"✓ N · ? M · ✗ K"`.

### 6. 계획 추가 CTA
- 기존 `EventPlanSheet` (R-feedback1 C2) 재사용. 미래 날짜 tap 시 이미 호출됨.

### 7. 알림 보내기
- `NotificationBroadcaster.swift` 신규:
  - `UNUserNotificationCenter.current().requestAuthorization` + 로컬 schedule 로 `"모든 멤버에게 알림을 보냈어요"` 토스트 + DB log deferred.
- 토스트 UI: `UnfadingToast` 신규 (bottom-anchored, 2s auto-dismiss).

### 8. 테스트
- `RSVPStoreTests` — summary 포맷 / toggle.
- UITest: `testCalendarDialOpensMonthPicker`, `testPlanCardVisibleInGeneralGroup`.

### 9. 아티팩트
- `contracts/round_calendar_dial_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_calendar_dial_plan.md`
- `reports/round_calendar_dial_r1/evidence/notes.md`

### 10. 빌드
- `xcodegen generate`
- `xcodebuild test -derivedDataPath .deriveddata/r33`

## Out of scope
- 실제 날씨 API (R38 이후).
- DB persistence of RSVP (R38).
