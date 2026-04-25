# round_tabbar_content_insets_r1 — Main content and overlays must reserve the compact tab bar area correctly

## Purpose
- 탭바가 콘텐츠를 가리거나 sheet가 탭바 밑으로 숨는 문제는 tabbar height와 content inset 모델이 분리되어 있지 않은 데서 재발한다. 목표는 탭바의 visual height와 reserved bottom inset이 일관되게 적용되는 것이다.

## Plan
- 수정 파일: `workspace/ios/App/UnfadingTabShell.swift` lines 79-134; `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 64-139, 529-533.
- 예상 변경 line 수: 25-45.
- 의존성: `round_tabbar_compact_height_r1` 선행.

## Acceptance (≤3)
1. `offlineQueueBanner`, incoming toast, current screen, sheet 계산이 같은 tabbar reserve 값을 사용한다.
2. tabbar compact 변경 후 map screen의 bottom affordances가 tabbar와 최소 8pt 이상 분리된다.
3. non-map tabs(calendar/settings)도 tabbar에 의해 주요 bottom content가 가려지지 않는다.

## Verification (3축)
- 코드: `UnfadingTabShell.swift:113-134` padding과 `MemoryMapHomeLayout.sheetTopY`의 bottom reserve가 같은 모델인지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): map/calendar/settings 각 탭 하단 screenshot으로 content/tabbar overlap 확인.
- 프로세스: `evidence/notes.md`에 탭별 bottom inset 적용 여부와 screenshot 경로 기록.

## Record
- `evidence/notes.md` 기록 항목: reserve 값, 탭별 overlap 판정, screenshot, remaining risk.
