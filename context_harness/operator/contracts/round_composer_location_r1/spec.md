# round_composer_location_r1 — Composer location & EXIF (F3/F4/F5/F6/F7)

**Stage:** coding_1st
**Implementer:** codex (partial) + claude_code (fallback — Codex capacity 회복 안 됨)
**Scope:** composer에서 장소/시각 자동 채움 + "이 위치가 아닌가요?" 3-tab picker

## Acceptance
- F4: `LocationPermissionStore`가 `MemoryMapApp`의 `.task` 에서 첫 실행 시 `handleCurrentLocationTap()` 호출 → notDetermined 이면 시스템 다이얼로그 표시.
- F3: `NearbyPlaceService.searchByName(_:near:)` — `MKLocalSearch.Request` 기반 한국어 자동완성.
- F5: `NearbyPlaceService.nearby(_:radiusMeters:)` — MKLocalPointsOfInterestRequest 반경 500m top-5.
- F6: `PhotoMetadataExtractor.extract(from:)` — `PHAsset.creationDate` + `PHAsset.location?.coordinate`.
- F7: `PlacePickerSheet` — 단일 sheet 3-tab(지도에서/검색/현재 위치).
- Composer: 사진 선택 시 첫 사진 seed 자동 적용, "이 위치가 아닌가요?" 엔트리 상시 표시, 근처 장소 chips.

## Implementer note
Codex 위임이 v5.7 기본이나, OpenAI 모델 capacity 반복 차단으로 3회 연속 turn.failed. Operator fallback (claude_code) 승인 — 메모리 feedback_codex_share_temp_2026-04-23 "Codex unavailable → operator fallback" 허용.

## Files changed
- workspace/ios/App/MemoryMapApp.swift — on-launch 권한 요청 + LocationPermissionStore 주입
- workspace/ios/Features/Composer/NearbyPlaceService.swift (신규, Codex 생성)
- workspace/ios/Features/Composer/PhotoMetadataExtractor.swift (신규, Codex 생성)
- workspace/ios/Features/Composer/PlacePickerSheet.swift (신규, operator)
- workspace/ios/Features/Home/MemoryComposerState.swift — photo seed + picked place + nearby refresh + 저장 시 selectedCoordinate 반영
- workspace/ios/Features/Home/MemoryComposerSheet.swift — seed banner + PlacePickerSheet 진입 + nearby chips
- workspace/ios/Shared/UnfadingLocalized.swift — Composer namespace 확장 (picker 관련 15 keys)
- workspace/ios/Tests/NearbyPlaceServiceTests.swift (신규)
- workspace/ios/Tests/PhotoMetadataExtractorTests.swift (신규)
- workspace/ios/Tests/MemoryComposerLocationSeedTests.swift (신규)

## Deferred
- "이 위치가 아닌가요?" 의 지도 pick 시 MapCameraPosition 현재 중심 좌표 추출은 region case 기반; `Map` 제스처 결과를 직접 binding하는 실시간 업데이트는 iOS 17+ onCameraChange 활용으로 개선 가능 (follow-up).
- MKLocalSearch 라이브 호출은 단위 테스트 stub 제한.
