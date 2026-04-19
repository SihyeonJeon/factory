# Sprint 26 — 시트 동작 수정 + Quick Fixes

## 목표
HF4 피드백 #1, #2, #3, #4 수정

## Fix 1 — 시트 스크롤 시 내용이 반투명하게 올라가는 문제 (#1)
현재 MainBottomSheet에서 스크롤하면 내용이 시트 밖으로 반투명하게 올라간다.
핸들과 내용이 같이 이동해야 함 → `.clipped()` 또는 시트 높이 내에서만 내용이 보이도록 수정.

**파일:** `Features/Home/MainBottomSheet.swift`
**수정:** VStack 전체에 `.clipped()` 적용하여 시트 경계 밖으로 내용이 보이지 않도록 함

## Fix 2 — 시트 expanded 상태에서 화면 100% 커버 + 핸들 숨김 (#2)
현재 expanded fraction = 1.0이지만 topClearance(140pt)가 있어 완전히 덮지 않음.
expanded 상태에서:
- topClearance = 0 (이미 구현됨, 확인)
- 핸들 숨김 (isMaximized일 때 opacity 0 + height 0 — 이미 구현됨, 확인)
- 시트가 SafeArea 포함 전체 화면 커버
- 라운드 코너 제거 (이미 구현: topLeadingRadius 0)

**확인 필요:** clampedHeight에서 topClearance=0일 때 containerHeight 전체를 사용하는지 확인.
현재: `let maxHeight = max(180, containerHeight - topClearance)` → topClearance=0이면 containerHeight 전체. OK.
하지만 사용자가 "여전히 전체를 덮지 않는다"고 하므로 safeArea가 문제일 수 있음.
**수정:** `.ignoresSafeArea(.all, edges: [.top, .bottom])` 이미 있으나, expanded일 때만. 시트 배경도 safeArea를 무시해야 함.

## Fix 3 — 캘린더 년도 반점 (#3)
`MonthlyCalendarGrid.swift:112`에서 `Text("\(year)년")` — Swift의 string interpolation이 Int를 locale-aware로 렌더링하여 "2,026년"처럼 반점이 들어감.
**수정:** `Text("\(year)년")` → `Text("\(String(year))년")` 또는 `Text(verbatim: "\(year)년")`

**파일:** `Features/Calendar/MonthlyCalendarGrid.swift:112`

## Fix 4 — 뒤로 버튼 위치 (#4)
현재 overlayHeader에서 뒤로 버튼이 우측 상단에 위치 (Spacer() 뒤).
**수정:** 뒤로 버튼을 핸들 극좌측에 배치. 텍스트("뒤로") 제거, 화살표(chevron.left)만 남김.
isFiltered일 때 핸들 좌측에 chevron.left 아이콘 버튼 배치.

**파일:** `Features/Home/MainBottomSheet.swift` overlayHeader 부분 (line 278~)

## 수정 대상 파일:
- Features/Home/MainBottomSheet.swift
- Features/Calendar/MonthlyCalendarGrid.swift

## 테스트:
xcodegen generate && xcodebuild test
