# Acceptance — round_sheet_true_fullscreen_r1

## A1. expanded 상태 full container height 사용
`UnfadingBottomSheet` body 가 `snap == .expanded` 일 때 `availableHeight` 를 `screenHeight - tabBarHeight` 가 아니라 `screenHeight + safeAreaInsets.top` (또는 동등한 full container) 으로 사용. expanded 의 fraction 1.0 이 화면 최상단 (Dynamic Island 영역 포함) 까지 도달.

## A2. expanded 배경 top safe area 커버
expanded 상태에서 sheet background 가 top safe area 와 Dynamic Island 주변까지 채워지게 `.ignoresSafeArea(.container, edges: .top)` 또는 동등한 edge ignore 적용. 상단 빈 띠 없음.

## A3. non-expanded 회귀 보존 + 단위 테스트
- collapsed / default snap 의 layout 은 기존 tabbar 회피 동작 (`screenHeight - tabBarHeight`) 유지.
- 단위 테스트 1건 이상: `BottomSheetSnap` 또는 helper 가 expanded vs non-expanded 에 다른 available-height 식을 적용함을 검증 (또는 fraction → height 계산 helper 추가하고 그 helper 의 expanded 케이스가 full height 를 반환함을 assert).
