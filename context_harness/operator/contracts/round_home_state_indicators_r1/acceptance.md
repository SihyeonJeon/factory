# Acceptance — round_home_state_indicators_r1

## A1. HomeStateIndicator label helper + overlay
순수함수 helper `MemoryMapHomeLayout.homeStateIndicatorText(activeCategoryName:hasSelection:)` 추가:
- 둘 다 nil/false → nil 반환 (indicator 숨김).
- category 만 있을 때 → `"필터: <name>"` 형식.
- 선택만 있을 때 → `"선택됨"` (또는 동등한 localized string).
- 둘 다 있을 때 → `"필터: <name> · 선택됨"`.

`MemoryMapHomeView.body` 에 indicator 오버레이 추가: helper 결과가 nil 이 아닐 때만 표시. 위치는 filter row 아래 또는 chrome 안쪽 (기존 layout 충돌 없음).

## A2. clear affordance
indicator 가 button (또는 indicator + close icon) 으로 동작. tap 시:
- `selection.clearSelection()`, `selectedMapItemID = nil`, `activeCategoryId = CategoryStore.allCategoryId` 모두 reset.
- 결과적으로 indicator 가 사라지고 sheet 가 default 콘텐츠로 복귀.

## A3. VoiceOver + 단위 테스트
- indicator 의 accessibilityLabel = helper 결과 (또는 localized 동등).
- accessibilityHint = "두 번 탭하면 필터와 선택을 해제합니다." (또는 동등).
- helper 단위 테스트 4건 (위 4개 case 모두 검증).
