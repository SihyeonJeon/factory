# round_tabbar_compact_height_r1 — Custom tab bar must be compact and lower on the screen

## Purpose
- 현재 하단 탭바는 `height = 83`으로 크고 높게 올라와 콘텐츠와 sheet 공간을 과도하게 차지한다. 목표는 HIG touch target을 유지하면서 시각 높이를 줄이고 하단에 더 붙은 tab bar다.

## Plan
- 수정 파일: `workspace/ios/App/UnfadingTabShell.swift` lines 277-344; 영향 확인 파일: `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 529-533, `workspace/ios/Shared/UnfadingBottomSheet.swift` lines 108-155.
- 예상 변경 line 수: 20-35.
- 의존성: 없음.

## Acceptance (≤3)
1. `UnfadingTabBar.height`가 83pt보다 낮아지고, 각 tab hit target은 최소 44pt를 유지한다.
2. icon+label visual stack이 하단 safe area 위에 밀착되어 "높게 떠 있는" 느낌을 줄인다.
3. tabbar height 변경이 sheet/FAB/mapControls 계산에 반영된다.

## Verification (3축)
- 코드: `UnfadingTabShell.swift:278,300-337`에서 height/visual stack/hit target이 분리되어 있는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): iPhone SE/16/16 Pro Max에서 tabbar가 콘텐츠를 과도하게 가리지 않고 44pt tap이 유지되는지 screenshot.
- 프로세스: `evidence/notes.md`에 before/after height, visual content height, hit target height 기록.

## Record
- `evidence/notes.md` 기록 항목: height 상수, touch target 근거, screenshot, impacted dependent rounds.
