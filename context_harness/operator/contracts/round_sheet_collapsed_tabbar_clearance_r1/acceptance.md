# Acceptance — round_sheet_collapsed_tabbar_clearance_r1

## A1. collapsed bottom 이 tabbar top + 8pt 위
`UnfadingBottomSheet` body 가 collapsed 일 때 `bottomInset` 에 최소 8pt clearance 를 추가 (또는 동등한 padding/Spacer). 결과적으로 collapsed 상태의 sheet 시각 bottom edge 가 `tabBarHeight + safeBottom + 8pt` 만큼 화면 하단에서 떨어진다.

## A2. 계산 모델 통일
`MemoryMapHomeLayout.sheetTopY(...)` 와 `UnfadingBottomSheet` body 가 같은 availableHeight / bottomInset 식을 사용하도록 정합. 두 곳 다 `screenHeight - tabBarHeight` 를 availableHeight 로 쓰고, `bottomInset = tabBarHeight + safeBottom + clearance(snap)` 를 적용 (clearance=8 for collapsed, 0 otherwise).

## A3. 단위 테스트
`MemoryMapHomeLayoutTests` 신규 또는 `UnfadingBottomSheetTests` 확장:
- `MemoryMapHomeLayout.sheetTopY(screenHeight: 800, safeBottom: 34, snap: .collapsed)` 결과의 sheet bottom (=screenHeight - tabBarHeight - safeBottom - clearance) 가 화면 하단에서 `tabBarHeight + 34 + 8 = 106pt` 떨어진 위치임을 assert.
- non-collapsed (default/expanded) 케이스는 clearance 0 적용.
