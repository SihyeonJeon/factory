# round_map_user_location_annotation_r1 — Home map must show and center on the user's current location

## Purpose
- 현재 지도에는 사용자 위치 annotation이 없고 현재 위치 버튼은 권한 store만 호출해 실제 지도 상태를 바꾸지 않는다. 목표는 권한 허용 시 내 위치가 지도에 표시되고 버튼이 현재 위치로 이동하는 것이다.

## Plan
- 수정 파일: `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 26, 240-275, 300-306; `workspace/ios/Shared/LocationPermissionStore.swift` lines 83-143.
- 예상 변경 line 수: 45-75.
- 의존성: 없음.

## Acceptance (≤3)
1. SwiftUI `Map`에 user location annotation 또는 equivalent 표시가 추가되어 권한 허용 시 내 위치가 보인다.
2. 현재 위치 버튼은 `.centerOnUser` 결과에서 실제 `cameraPosition`을 사용자 좌표 주변 region으로 변경한다.
3. 권한 거부/제한/미결정 상태는 기존 recovery prompt 흐름을 유지하고, 권한 승인 후 refresh로 표시가 활성화된다.

## Verification (3축)
- 코드: `MemoryMapHomeView.swift:240-275`에 user location 표시가 있고 `MapControlsSection` action이 `cameraPosition` 변경까지 연결되는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): simulator location set 후 현재 위치 버튼 tap, 지도 중심이 simulator 좌표로 이동하고 user marker가 표시되는지 screenshot.
- 프로세스: `evidence/notes.md`에 permission state, simulator coordinate, camera center before/after 기록.

## Record
- `evidence/notes.md` 기록 항목: CLLocation source, permission branch별 결과, screenshot, UITest/smoke 절차.
