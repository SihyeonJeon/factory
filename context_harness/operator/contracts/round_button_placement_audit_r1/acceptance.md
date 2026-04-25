# Acceptance — round_button_placement_audit_r1

## A1. HomeActionInventory 구조화
`MemoryMapHomeLayout` 또는 동일 파일 안에 `HomeAction` 구조 (name, identifier, zone, hitTarget) 와 `homeActionInventory: [HomeAction]` 정적 배열 추가:
- zone enum: `.topNavigation` / `.mapControls` / `.composing` / `.indicator`
- 최소 7개 entry: search, group switch, current location, reset orientation, FAB, category edit, home-state-indicator (필요 시 추가).
- 각 entry 의 identifier 는 코드에서 실제 사용되는 `accessibilityIdentifier` 와 일치.

## A2. category edit `+` 명확화
`home-filter-add-category` 버튼에 `accessibilityHint` 추가 (예: "두 번 탭하면 새 카테고리를 추가합니다"). 시각적 secondary style (dashed stroke / opacity 0.66) 은 보존. accidental primary action 으로 보이지 않게 유지.

## A3. 단위 테스트
- inventory 가 최소 7개 entry 를 가짐 assert.
- 모든 entry 의 identifier 가 non-empty.
- 모든 entry 의 hitTarget ≥ 44pt.
- 4개 zone 이 모두 ≥1개 entry 보유 (topNavigation / mapControls / composing / indicator).
