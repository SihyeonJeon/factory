# Acceptance — round_tabbar_compact_height_r1

## A1. Tabbar visual height 축소 + 44pt tap target 유지
`UnfadingTabBar.height` 상수가 기존 83 보다 작아짐 (60–72 권장). 각 tab button 의 hit area (`frame(height:)` 또는 `contentShape`) 는 최소 44pt 유지.

## A2. 시각적 stack 하단 밀착
icon+label VStack 의 .frame alignment / padding 이 bottom safe area 에 가깝게 (top padding 축소 또는 .bottom alignment) 변경. "둥둥 떠 있는" 인상 제거.

## A3. 의존 layout 갱신 확인
`MemoryMapHomeView` (mapControls/FAB) 와 `UnfadingBottomSheet` (sheet height 계산) 가 `UnfadingTabBar.height` 상수를 읽거나 호출 site 가 새 값을 받아 layout 이 자동 반영. 회귀 테스트 또는 단위 테스트 1건 이상 (예: tabbar height < 80 assert).
