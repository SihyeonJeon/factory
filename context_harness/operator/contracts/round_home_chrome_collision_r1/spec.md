# round_home_chrome_collision_r1 — Home top chrome/search/filter/map controls must have explicit non-overlap zones

## Purpose
- 검색창과 상단 chrome이 낮고, filter row 및 map controls가 sheet/FAB와 겹칠 위험이 있다. 목표는 검색 버튼이 더 위로 올라가고 모든 home chrome이 명시적인 safe zone 안에서 서로 겹치지 않는 배치다.

## Plan
- 수정 파일: `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 64-107, 511-528, 548-608, 642-718.
- 예상 변경 line 수: 40-70.
- 의존성: `round_tabbar_compact_height_r1`, `round_sheet_collapsed_tabbar_clearance_r1` 후 최종 검증.

## Acceptance (≤3)
1. `MemoryMapHomeLayout`에 top chrome, filter row, map controls, sheet top 사이의 최소 gap 상수가 있고, layout 계산에서 사용된다.
2. 검색 버튼 포함 `TopChromeSection`은 현재 `topChromeTop = 54`보다 위쪽 기준으로 재배치되며 Dynamic Island/safe-area와 충돌하지 않는다.
3. collapsed/default 상태에서 group pill, search, filter chips, map controls, FAB, sheet가 서로 시각적으로 겹치지 않는다.

## Verification (3축)
- 코드: `MemoryMapHomeView.swift:514-527`의 hard-coded top/gap 상수가 명시적 non-overlap 모델로 정리됐는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): collapsed/default 상태 스크린샷에 각 chrome bounding box를 notes에 수동 표기.
- 프로세스: `evidence/notes.md`에 viewport별 collision matrix(TopChrome/Filter/Controls/FAB/Sheet/TabBar)를 기록.

## Record
- `evidence/notes.md` 기록 항목: 변경 전 좌표, 변경 후 좌표, collision matrix, screenshot 경로.
