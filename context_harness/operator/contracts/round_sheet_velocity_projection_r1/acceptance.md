# Acceptance — round_sheet_velocity_projection_r1

## A1. velocity-projected snap (관성)
`BottomSheetDragResolution.resolvedSnap(...)` 가 velocity threshold OR projected-end bucket 사용. 짧은 거리 + 빠른 swipe 도 인접 snap (collapsed↔default 또는 default↔expanded) 으로 한 단계 이동.

## A2. 느린 drag 호환 + 방향 역전 금지
느린 drag (low velocity) 는 기존 nearest-only 동작 유지. fast fling 이 `collapsed → expanded` 방향을 역전하지 않음 (e.g. upward fling 이 collapse 로 가지 않음).

## A3. 단위 테스트 표
`UnfadingBottomSheetTests` 에 다음 케이스 모두 추가:
- low-translation + high-velocity upward (default → expanded).
- low-translation + high-velocity downward (default → collapsed).
- low-translation + low-velocity (변화 없거나 nearest).
- high-translation + low-velocity (기존 nearest).
