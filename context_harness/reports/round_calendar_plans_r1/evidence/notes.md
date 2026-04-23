# round_calendar_plans_r1 — evidence notes

## KST 처리 핵심
- 저장: DB는 tstz (UTC). 클라이언트 전 표시 `Calendar(identifier: .gregorian) + timeZone = Asia/Seoul`.
- 월 범위 쿼리: `planned_events_for_range_kst(start_utc, end_utc)` 에 KST 월 시작/끝 을 UTC 변환 후 전달.
- 월 지출 RPC: 서버에서 `extract(... from (m.date at time zone 'Asia/Seoul'))` 로 KST 월 일치 계산.

## 자정 경계
- 테스트 `testStartOfMonthKSTReturnsUTCMidnightMinusNineHours`: KST 2026-05-01 00:00 ↔ UTC 2026-04-30 15:00 왕복 확인.
- `testIsFutureMidnightBoundary`: 오늘 자정은 미래가 아닌 오늘로 간주.

## 미래 vs 과거 셀
- `hasMemory(date)` 콜백에서 `isFutureDate(date)` 일 때 항상 false 반환 → 미래에 memory dot 안 찍힘.
- `CalendarView.dayContentList`: 선택 날짜가 미래면 `EventPlanSheet` 자동 오픈 + "계획 추가" CTA.

## 알람 스케줄링 실패 graceful
- `UNUserNotificationCenter.requestAuthorization` 거부 → `reminderPermissionDenied = true` 배너만 노출, 이벤트는 저장.

## 향후 follow-up
- MemoryCalendarStore 실제 MemoryStore.memories 기반으로 교체 (C1 같은 라운드).
- 알람 재스케줄 (앱 재설치/시간 변경 시 UNCalendarNotificationTrigger 재등록).
- 월 초/말 경계 로케일 차이(토요일 시작 vs 일요일 시작) 테스트 추가.
