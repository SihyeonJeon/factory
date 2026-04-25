# Acceptance — round_home_chrome_collision_r1

## A1. 명시적 non-overlap gap 상수 + helper
`MemoryMapHomeLayout` 에 다음을 추가:
- `topChromeMargin: CGFloat` (safe area top 부터 chrome top 까지의 여백, 8pt 권장).
- `topChromeBottomToFilterGap: CGFloat` (chrome bottom 부터 filter top 까지의 gap, 8pt 권장).
- `topChromeY(safeTop:)` helper: `safeTop + topChromeMargin` 반환.
- `filterChipY(safeTop:)` helper: `topChromeY + topChromeHeight + topChromeBottomToFilterGap` 반환.

기존 hardcoded `topChromeTop = 54`, `filterChipTop = 108` 은 호환성 위해 보존 가능하지만 body 의 position 계산이 helper 사용으로 교체된다.

## A2. TopChromeSection Dynamic Island 충돌 회피
`MemoryMapHomeView.body` 의 topChrome / filterRow `.position(y:)` 가 `topChromeY(safeTop: proxy.safeAreaInsets.top)` / `filterChipY(safeTop:)` 로 변경. 결과적으로 iPhone 17 Pro (safeTop ~59pt) 에서 chrome top 이 ≥ 67pt 로 Dynamic Island 영역을 침범하지 않음.

## A3. collision-free 단위 테스트
`UnfadingBottomSheetTests` 또는 신규 `MemoryMapHomeLayoutTests` 에:
- `topChromeY(safeTop: 59)` == 67 (또는 정확히 `safeTop + 8`).
- `filterChipY(safeTop: 59)` == `topChromeY + topChromeHeight + 8`.
- filter bottom < sheetTopY(default snap) 검증 (collision-free invariant).
