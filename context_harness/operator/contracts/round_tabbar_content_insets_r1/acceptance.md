# Acceptance — round_tabbar_content_insets_r1

## A1. tabBarReserve 단일 소스
`MemoryMapHomeLayout.tabBarReserve(safeBottom:)` 와 같은 helper 추가 (또는 동등): `UnfadingTabBar.height + safeBottom` 반환. offlineQueueBanner / incoming toast overlay padding 이 이 helper 의 결과를 사용 (기존 hardcoded `UnfadingTabBar.height + Spacing.sm` 대신 `tabBarReserve(safeBottom:) + Spacing.sm`).

## A2. map 탭 bottom affordance 와 tabbar 분리
map 탭에서 FAB / mapControls 는 sheetTop 또는 tabBarReserve 를 통해 tabbar 와 시각적으로 겹치지 않음 (R65/R69 에서 이미 tabbar 64pt + collapsed 8pt 확보됨). 회귀 단위 테스트 1건 이상: tabBarReserve 가 tabbar height + safeBottom 을 반환함을 assert.

## A3. non-map 탭 컨텐츠 reserve
`currentScreen` 의 calendar/settings 분기 (또는 ZStack 전체) 에 `.safeAreaInset(edge: .bottom, ...)` 또는 `.padding(.bottom, tabBarReserve(safeBottom))` 적용 → CalendarView/SettingsView 의 마지막 row/section 이 tabbar 에 가려지지 않음. map 탭은 기존처럼 ignoresSafeArea/full bleed 유지.
