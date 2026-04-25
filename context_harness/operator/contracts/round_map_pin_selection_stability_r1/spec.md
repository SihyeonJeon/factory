# round_map_pin_selection_stability_r1 — Place selection must preserve the coordinate the user selected

## Purpose
- 장소 지도에서 선택해도 앱이 근처 다른 장소 좌표로 핀을 옮기는 문제가 있다. 목표는 사용자가 지도 중심으로 고른 좌표는 그대로 저장하고, 가까운 장소명/주소는 보조 metadata로만 쓰는 것이다.

## Plan
- 수정 파일: `workspace/ios/Features/Composer/PlacePickerSheet.swift` lines 124-139; `workspace/ios/Features/Composer/NearbyPlaceService.swift` lines 62-64, 111-130; 필요 시 `workspace/ios/Features/Home/MemoryComposerState.swift` lines 159-168.
- 예상 변경 line 수: 25-45.
- 의존성: 없음.

## Acceptance (≤3)
1. `confirmMapCenter()`는 `resolver.closestMatch(to:)`가 성공해도 `PickedPlace.coordinate`를 `currentCenter`로 유지한다.
2. 장소명/주소는 closest match 또는 reverse geocode 결과를 사용할 수 있으나, 좌표를 POI 좌표로 대체하지 않는다.
3. 단위 테스트가 "center와 closest POI 좌표가 다를 때 저장 좌표는 center"를 검증한다.

## Verification (3축)
- 코드: `PlacePickerSheet.swift:124-139`의 `place = match.pickedPlace`가 좌표 보존 방식으로 바뀌었는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): 지도 중심을 POI 옆 도로/공원 지점에 둔 뒤 선택하고 composer coordinate가 중심 좌표와 일치하는지 로그/테스트로 확인.
- 프로세스: `evidence/notes.md`에 center coordinate, matched POI coordinate, saved coordinate를 함께 기록.

## Record
- `evidence/notes.md` 기록 항목: 재현 좌표, closest match 결과, 저장 좌표, 테스트명.
