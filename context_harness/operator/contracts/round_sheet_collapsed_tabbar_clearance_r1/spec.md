# round_sheet_collapsed_tabbar_clearance_r1 — Collapsed sheet must remain visible above the tab bar

## Purpose
- 사용자 실기기에서 collapsed sheet가 하단 탭바 밑으로 숨는 현상이 재발했다. 목표는 collapsed summary와 handle이 탭바 위에 안정적으로 노출되고 탭바와 겹치지 않는 것이다.

## Plan
- 수정 파일: `workspace/ios/Shared/UnfadingBottomSheet.swift` lines 151-217, `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 529-533.
- 예상 변경 line 수: 25-40.
- 의존성: `round_tabbar_compact_height_r1` 선행 권장.

## Acceptance (≤3)
1. collapsed snap의 visual bottom이 tabbar top + 최소 8pt 여백 위에 위치한다.
2. `MemoryMapHomeLayout.sheetTopY`와 실제 `UnfadingBottomSheet` bottom padding 계산이 같은 tabbar/safe-area 모델을 사용한다.
3. collapsed/default/expanded 각각에서 FAB와 map controls가 sheet와 tabbar 사이에 겹치지 않는다.

## Verification (3축)
- 코드: `UnfadingBottomSheet.swift:154-157,216`와 `MemoryMapHomeView.swift:529-533` 계산이 서로 같은 기준인지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): iPhone SE, iPhone 16, iPhone 16 Pro Max에서 collapsed screenshot을 찍어 handle/summary/tabbar bounding box가 분리됐는지 기록.
- 프로세스: `evidence/notes.md`에 기기별 safeBottom, tabbar height, collapsed top/bottom 추정값 기록.

## Record
- `evidence/notes.md` 기록 항목: 재발 원인, 계산식 diff 요약, 기기별 screenshot, overlap 판정.
