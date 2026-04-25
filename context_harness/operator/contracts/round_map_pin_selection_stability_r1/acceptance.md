# Acceptance — round_map_pin_selection_stability_r1

## A1. confirmMapCenter 좌표 보존
`PlacePickerSheet.confirmMapCenter()` 가 `resolver.closestMatch(...)` 성공 분기에서도 `PickedPlace.coordinate == currentCenter` 가 되도록 변경. POI 좌표로 대체하지 않음.

## A2. 보조 metadata 활용
closest match 또는 reverse geocode 결과의 `name` / `address` 는 그대로 사용 가능 (이름/주소만 가져오고 좌표는 center 유지). 실패 분기 (`nil`) 는 기존 placeholder 동작.

## A3. 단위 테스트 추가
`NearbyPlaceServiceTests` 또는 신규 `PlacePickerCoordinatePreservationTests` 에 다음 케이스:
- center 좌표가 POI 좌표와 다를 때 (예: center=(37.500, 127.000), POI=(37.501, 127.002)) `pickedPlace(at: center)` 같은 helper 또는 직접 PickedPlace 구성 결과의 coordinate 가 center 와 일치 (≤1e-6 accuracy).
- name/address 는 match 에서 옴.
