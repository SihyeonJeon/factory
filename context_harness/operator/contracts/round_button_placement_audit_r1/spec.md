# round_button_placement_audit_r1 — Home action buttons must be placed by task frequency and spatial ownership

## Purpose
- 사용자는 버튼들이 엉뚱한 위치에 있다고 보고했지만 구체 버튼을 특정하지 않았다. 목표는 홈 화면의 버튼 위치를 실제 task ownership 기준으로 audit하고, 자주 쓰는 행동은 예측 가능한 위치에 배치하는 것이다.

## Plan
- 수정 파일: `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 79-107, 277-306, 548-718; `workspace/ios/App/UnfadingTabShell.swift` lines 91-103.
- 예상 변경 line 수: 35-65.
- 의존성: `round_home_chrome_collision_r1`, `round_tabbar_compact_height_r1` 선행.

## Acceptance (≤3)
1. Home의 primary actions(search, current location, reset orientation, compose, group switch, category edit)가 "상단 탐색/지도 제어/작성" 영역으로 분류되어 위치가 일관된다.
2. category edit `+`는 filter row의 끝에 남기되 시각적으로 "새 카테고리"임이 명확하고 accidental primary action처럼 보이지 않는다.
3. 각 icon-only 버튼은 accessibilityIdentifier와 label이 있으며 44pt 이상 hit target을 유지한다.

## Verification (3축)
- 코드: `MemoryMapHomeView.swift:583-593,669-684,703-713`와 `UnfadingTabShell.swift:91-103`의 action placement가 audit table과 일치하는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): 홈 화면 screenshot에 버튼별 번호를 매겨 notes에 task/placement rationale 기록.
- 프로세스: `evidence/notes.md`에 button inventory table(action, current line, target zone, final position, reason)을 기록.

## Record
- `evidence/notes.md` 기록 항목: 버튼 inventory, 이동/유지 결정, screenshot, a11y check.
