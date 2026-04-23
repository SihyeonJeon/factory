# round_composer_location_r1 — evidence notes

## 구현 경로
| 요구 | 기법 |
|---|---|
| F3 장소 이름 검색 | `MKLocalSearch.Request(naturalLanguageQuery:, region: 반경 1km)` |
| F4 on-launch 권한 | `MemoryMapApp.task` → `LocationPermissionStore.handleCurrentLocationTap()` (notDetermined 이면 system prompt, 나머지는 refresh) |
| F5 근처 장소 | `MKLocalPointsOfInterestRequest(center, radius: 500m)` → 거리순 top-5 chips |
| F6 첫 사진 seed | `PHAsset.creationDate` + `PHAsset.location` → `PhotoSeed` → `applyPhotoSeed` |
| F7 "이 위치가 아닌가요?" | `PlacePickerSheet` segmented 3-tab (지도/검색/현재 위치). 현재 위치 탭은 `LocationPermissionStore.handleCurrentLocationTap()` + `CLLocationManager().location` + `NearbyPlaceService.closestMatch` |

## photoSeedApplied 상태 표
| 현재값 | setTime(user) | setPlace(user) | 비고 |
|---|---|---|---|
| .locationAndTime | → .locationOnly | → .locationAndTime (place slot 그대로) | 메모 편집은 영향 없음 |
| .timeOnly | → .none |  | |
| .locationOnly |  | → .none | |
| .none |  |  | |

## Codex fallback 로그
1회차: turn.failed — "Selected model is at capacity. Please try a different model."
2회차: stream disconnects 4회 후 capacity.
3회차(sequential): 동일 capacity.
Operator fallback 발동 시각: 2026-04-23T17:10Z.

## 향후 follow-up
- MKLocalSearch 한국 POI 결과 품질 튜닝
- PlacePickerSheet 지도 탭: `Map.onMapCameraChange`로 center coord 실시간 반영
- userEditedTime 플래그 분리로 seed 로직 정밀화
