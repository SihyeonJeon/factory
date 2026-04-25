# Acceptance — round_map_user_location_annotation_r1

## A1. User location annotation 표시
SwiftUI `Map` 컨텐트에 `UserAnnotation()` (또는 `MapUserLocationButton`/equivalent) 가 추가되어 권한 허용 상태에서 시뮬레이터/실기기 location 이 점/마커로 보인다.

## A2. 현재 위치 버튼이 cameraPosition 변경
`onShowCurrentLocation` 콜백이 `LocationPermissionStore.handleCurrentLocationTap()` 의 `.centerOnUser` 결과에서 `cameraPosition` 을 `.userLocation(fallback: ...)` 또는 사용자 좌표 기반 region 으로 업데이트한다 (single point of update — 기존 placeholder 호출만 남기는 회귀 금지).

## A3. 권한 거부/제한 흐름 보존 + 단위 테스트
- `.requestSystemPermission` / `.showRecoveryPrompt` 분기는 기존 동작 유지 (recovery prompt 노출 등).
- 단위 테스트 1건 이상: `LocationPermissionStore.handleCurrentLocationTap()` 의 `.centerOnUser` / `.requestSystemPermission` / `.showRecoveryPrompt` 각 status 별 결과 보존 확인 — 기존 테스트 보존 또는 추가.
