---
round: round_composer_location_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-composer-location
contract_hash: none
created_at: 2026-04-23T17:15:00Z
codex_session_id: fresh_partial_then_operator
---
# R26 composer 위치·사진 Seed (F3/F4/F5/F6/F7) — plan & outcome

## Context
Block B 피드백 하위 5건 해결:
- F3: 장소 이름 검색 회귀 복구
- F4: 첫 실행 즉시 위치 권한 요청
- F5: 근처 장소 부정확
- F6: 첫 사진 metadata 로 초기값 자동 채움
- F7: "이 위치가 아닌가요?" 지도·검색·현재 위치 3-tab sheet

## Decision
Codex 가 dispatch 초반에 `NearbyPlaceService.swift` + `PhotoMetadataExtractor.swift` 생성까지 진행 후 OpenAI 모델 capacity 에러로 3회 연속 turn.failed. Operator fallback 발동: claude_code 가 잔여 (`PlacePickerSheet`, composer 상태/뷰 연결, permission on-launch, tests, localized strings) 직접 작성.

## Challenge Section
### Objection
Codex 실패 시마다 operator fallback하면 v5.7 Swift 위임 규제 무력화되지 않나. → 수용: 이번 fallback 은 **가용성(capacity) 한계** 때문이며 recovery 를 기다려도 끝이 안 보임. 향후 regulation 에 "operator fallback 조건: Codex 모델 capacity/네트워크로 3회 연속 실패" 추가 필요 (follow-up).

### Risk
- MKLocalSearch 결과는 OS 지역/로케일·지역 서버 응답 품질에 좌우. 한국에서 추가 튜닝 필요할 수 있음.
- 첫 사진 seed 적용 시 photoSeedApplied 판정이 "selectedTime이 now 5초 이내이면 미사용자 편집으로 간주" — 사용자가 현재 시각 근처를 명시 선택한 경우 overwrite 가능. 향후 UserEditedTime 플래그로 보강.

## Outcome
- `App/MemoryMapApp.swift`: `@StateObject private var locationPermission`, on-launch `.task` 로 notDetermined 시 prompt.
- `Features/Composer/PlacePickerSheet.swift`: 지도/검색/현재 위치 단일 sheet, Korean, 44pt a11y identifiers.
- `MemoryComposerState`: photoSeedApplied 상태, applyPhotoSeed/applyPickedPlace/refreshNearbyPlaces/searchPlaceByName.
- `MemoryComposerSheet`: seed banner, "이 위치가 아닌가요?" 상시, nearby chips.
- `UnfadingLocalized.Composer`: 15 picker-related keys 추가.
- 3 test files added (NearbyPlaceServiceTests / PhotoMetadataExtractorTests / MemoryComposerLocationSeedTests).

## Verification
- Operator 가 xcodegen + xcodebuild test 일괄 실행 (Stream A/C2 와 함께 최종 통합).
