# round_home_state_indicators_r1 — Home map must expose visible state indicators for selection and filters

## Purpose
- 현재 선택된 핀, 활성 카테고리, sheet tab 등 앱 상태가 명확히 보이지 않아 사용자가 지금 어떤 상태인지 모니터링하기 어렵다. 목표는 지도 화면에서 핵심 상태가 작고 명확한 indicator로 보이는 것이다.

## Plan
- 수정 파일: `workspace/ios/Features/Home/MemoryMapHomeView.swift` lines 124-136, 288-298, 386-425, 548-692.
- 예상 변경 line 수: 50-85.
- 의존성: `round_home_chrome_collision_r1` 선행.

## Acceptance (≤3)
1. 활성 카테고리와 선택된 pin/cluster 상태가 지도 상단 또는 sheet header에 짧은 label/badge로 표시된다.
2. 선택 해제 affordance가 보이며, `selection.clearSelection()` 시 indicator와 map selection이 함께 사라진다.
3. VoiceOver/accessibilityValue가 활성 필터와 선택 상태를 읽을 수 있다.

## Verification (3축)
- 코드: `MemoryMapHomeView.swift:417-424,441-451` selection sync 흐름과 indicator UI가 같은 state source를 쓰는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): category toggle, pin tap, clear 순서로 screenshot 3장을 기록.
- 프로세스: `evidence/notes.md`에 상태 전이 표(activeCategoryId, selectedMapItemID, selectedPinID, visible indicator)를 기록.

## Record
- `evidence/notes.md` 기록 항목: state source, indicator 위치, accessibility label/value, screenshot 경로.
