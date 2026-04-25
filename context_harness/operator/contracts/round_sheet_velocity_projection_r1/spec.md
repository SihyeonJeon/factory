# round_sheet_velocity_projection_r1 — Bottom sheet swipe velocity must project to the intended snap

## Purpose
- 현재 시트는 적당히 빠르게 밀어도 목표 snap 가까이까지 끌고 가야 전환된다. 목표는 사용자가 빠르게 던지는 제스처의 방향과 속도를 반영해 한 단계 이상 자연스럽게 snap 되는 관성 동작이다.

## Plan
- 수정 파일: `workspace/ios/Shared/UnfadingBottomSheet.swift` lines 70-102, 249-267, 277-293.
- 예상 변경 line 수: 35-55.
- 의존성: 없음.

## Acceptance (≤3)
1. `BottomSheetDragResolution`이 velocity threshold 또는 projected-end bucket을 사용해, 짧은 거리의 빠른 upward/downward drag를 인접 snap으로 해석한다.
2. 느린 drag는 기존처럼 가장 가까운 snap 기준으로 동작하며, fast fling은 `collapsed <-> default <-> expanded` 방향을 역전하지 않는다.
3. `BottomSheetDragResolution` 단위 테스트가 low-translation/high-velocity upward 및 downward 사례를 포함한다.

## Verification (3축)
- 코드: `UnfadingBottomSheet.swift:70-102`의 `velocityProjectionSeconds = 0.2` + nearest-only 로직이 threshold/bucket 기반 해석으로 교체됐는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): iPhone 16/실기기에서 default sheet를 빠르게 위로 밀면 expanded, expanded를 빠르게 아래로 밀면 default 또는 collapsed로 이동하는지 녹화/스크린샷.
- 프로세스: `context_harness/reports/round_sheet_velocity_projection_r1/evidence/notes.md`에 drag 시작 snap, 방향, 결과 snap을 표로 기록.

## Record
- `evidence/notes.md` 기록 항목: 변경 전 라인 근거, velocity 기준값, 단위 테스트명, smoke 기기/시뮬레이터, PASS/FAIL.
