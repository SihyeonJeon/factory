# round_sheet_true_fullscreen_r1 — Expanded bottom sheet must occupy true fullscreen including Dynamic Island area

## Purpose
- 현재 expanded sheet는 탭바와 safe-area 계산 때문에 Dynamic Island 근처 상단 영역이 비어 true fullscreen처럼 보이지 않는다. 목표는 expanded 상태에서 시트 배경과 콘텐츠가 화면 최상단까지 이어지는 전체 화면 경험이다.

## Plan
- 수정 파일: `workspace/ios/Shared/UnfadingBottomSheet.swift` lines 151-223, `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 109-139.
- 예상 변경 line 수: 25-45.
- 의존성: `round_tabbar_compact_height_r1`과 독립이나, 검증 시 tabbar 변경 후 재확인 필요.

## Acceptance (≤3)
1. `snap == .expanded`일 때 `availableHeight`가 tabbar height를 빼지 않는 full container height를 사용한다.
2. expanded 상태의 sheet background가 top safe area와 Dynamic Island 주변까지 끊김 없이 채운다.
3. non-expanded 상태의 collapsed/default sheet는 기존 tabbar 회피 동작을 유지한다.

## Verification (3축)
- 코드: `UnfadingBottomSheet.swift:153-157`의 `screenHeight - tabBarHeight` 계열 계산이 expanded/non-expanded 별도로 분기되는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): iPhone 15/16 Pro 계열에서 `-UI_TEST_SHEET_SNAP=expanded` 실행 후 상단 safe-area 빈 띠가 없는 스크린샷 첨부.
- 프로세스: `evidence/notes.md`에 expanded와 default 각각의 top/bottom coverage 판정과 스크린샷 경로 기록.

## Record
- `evidence/notes.md` 기록 항목: full-height 계산식, 영향 받은 safe-area edge, before/after 스크린샷 경로, verifier 판정.
