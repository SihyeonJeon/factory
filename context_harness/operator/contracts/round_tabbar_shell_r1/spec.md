# round_tabbar_shell_r1 — Custom 3-tab shell + FAB 홈 오버레이

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only session)
**Dependencies:** round_design_tokens_r1 완료 선행 (UnfadingTheme.Color/Shadow 토큰 사용).

## Objective
네이티브 `TabView` → 커스텀 3-tab shell 로 전면 교체. 탭바를 zIndex 120 으로 항상 위에 그리고, sheet/FAB/모달을 공통 root `ZStack` 의 형제 레이어로 둠 (R28 BottomSheet 재작성의 기반).

## Authoritative Source
`docs/design-docs/unfading_ref/design_handoff_unfading/README.md` 섹션 "Global Layout System / 고정 z-레이어" + "State Model / 상태 전이 규칙" + "9. Group Hub (설정)".

## 핵심 차이 (현재 vs 목표)

| 항목 | 현재 (native TabView) | 목표 (custom shell) |
|---|---|---|
| 탭 개수 | 5 (지도/캘린더/추억/리와인드/설정) | **3 (지도/캘린더/설정)** |
| 추억 작성 | "추억" 탭 intercept → composer | FAB(+) 홈 오버레이 → composer fullScreenCover |
| 리와인드 진입 | 별도 탭 | 홈 큐레이션 섹션 "Rewind 힌트" 카드 |
| 탭바 zIndex | TabView 시스템 기본 | **120 (모든 콘텐츠 위)** |
| 레이아웃 루트 | `TabView` | `ZStack` with ordered children |

## Acceptance

### 1. UnfadingTabShell (신규)
`workspace/ios/App/UnfadingTabShell.swift`:
- 3-tab enum `ShellTab: String, CaseIterable { case map, calendar, settings }`.
- `@State var selectedTab: ShellTab`.
- Root `ZStack(alignment: .bottom)` 안에 선택된 탭 화면 + FAB(홈만) + 커스텀 탭바.
- 탭바는 `UnfadingTheme.Color.sheet` 배경 + 0.5px `divider` 상단 경계 + bottom safe-area padding 처리.
- 탭 아이콘 + 라벨 (지도: `map`, 캘린더: `calendar`, 설정: `gearshape`), 활성 탭은 primary 색.
- 탭바 height = 83pt (iOS 표준 + safe area).
- `.zIndex(120)` 로 모든 화면 위.

### 2. RootTabView 교체
`workspace/ios/App/RootTabView.swift` 를 wrapper 로 변경 (backward-compat):
- 내부적으로 `UnfadingTabShell` 렌더.
- `evidenceMode` 파라미터 유지.
- `-UI_TEST_GROUP_STUB` flow 호환.

### 3. FAB 홈 오버레이
`workspace/ios/Features/Home/ComposeFAB.swift` (신규):
- `Circle() 56x56` primary gradient, `+` 18pt, `Shadow.activeCard` 사용.
- 위치: 하단 탭바 위 18pt, 우측 18pt (`padding(.bottom, 83 + 18)`, `.padding(.trailing, 18)`).
- Tap → composer `fullScreenCover` 제시.
- zIndex 70 (README 스펙).
- `.zIndex(sheetExpanded ? 0 : 70)` — expanded 시 숨김은 R28 scope, 여기선 기본 70.
- A11y: `accessibilityIdentifier("home-fab")`, `accessibilityLabel("새 추억")`.

### 4. MemoryMapHomeView 확장
- 기존 구조 유지하되 FAB 는 `UnfadingTabShell` 레벨에서 그려지므로 HomeView 에서 제거.
- 큐레이션 섹션에 **"Rewind 힌트"** 카드 추가:
  - 조건: 월말 또는 DEV 모드 always on.
  - Tap → `RewindFeedView` 를 `NavigationStack` push 또는 sheet 로 제시.
  - 재사용 자산: 기존 `UnfadingCardBackground` + `UnfadingPrimaryButtonStyle`.

### 5. RewindFeedView 라우팅
- 기존 RewindFeedView 는 기능 변경 없음. 진입 경로만 변경.
- UITest `testRewindTabScreenshot` 교체: 탭 직접 진입 대신 홈 → 스크롤 → Rewind 힌트 카드 tap → 스크린샷.

### 6. UITest 마이그레이션
`workspace/ios/UITests/UnfadingUITests.swift` 전면 점검:
- 5-tab 가정하는 모든 `tabBars.buttons[...]` 호출을 새 custom 탭바 `app.buttons["tab-지도"]` / `"tab-캘린더"` / `"tab-설정"` 으로 변경.
- `testComposerOpenScreenshot` — 현재 "추억" 탭 tap → composer 진입. 이제 FAB tap 으로 변경.
- `testRewindTabScreenshot` — 위 5번 경로로 변경.
- 새 테스트 추가: `testHomeFABPresentsComposer` (FAB 존재 + tap → composer 식별자 존재).
- 새 테스트 추가: `testCustomTabBarAlwaysVisible` (설정 탭에서도 지도/캘린더/설정 모든 버튼 존재).

### 7. RootNavigationTests
`workspace/ios/Tests/RootNavigationTests.swift` 5-tab 기반 assertion 을 3-tab 으로 재작성:
- `ShellTab.allCases.count == 3` assert.
- previous/compose-intercept 테스트 제거 (compose 는 이제 FAB, 탭 선택 흐름 없음).

### 8. UnfadingLocalized
`enum Tab` namespace 에서 `compose`, `rewind` 키 **제거 금지** (backward-compat). 다만 custom 탭바 UI는 `UnfadingLocalized.Tab.map/calendar/settings` 만 사용.
`UnfadingLocalized.Home` 에 `rewindHintTitle`, `rewindHintBody`, `rewindHintCta` 추가.

### 9. 아티팩트
- `contracts/round_tabbar_shell_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_tabbar_shell_plan.md` — Challenge Section (objections/risks/rejected alt) 본인이 직접 작성.
- `reports/round_tabbar_shell_r1/evidence/notes.md` — zIndex 결정, FAB 위치 계산, UITest 마이그레이션 범위, 회귀 리스크 표.

### 10. 빌드·테스트
- `xcodegen generate`.
- `xcodebuild test` — 전부 통과 목표. 깨진 기존 UITest 는 본 라운드에서 교체하면서 통과하게 만들어야.
- 최소 신규 테스트: 3개 (Custom tab bar 3-tab count, FAB presents composer UITest, Rewind hint card UITest).

## Out of scope
- BottomSheet 동작 자체 (R28 스코프). 현재 sheet 구현은 그대로 두되, FAB 는 sheet expanded 여부를 **무시**한 채 zIndex 70 고정 (R28 에서 `sheetExpanded` binding 으로 hide 처리).
- 홈 큐레이션의 나머지 카드 레이아웃 (R29 scope).
- TopChrome/FilterChipBar/MapControls 좌표 정밀화 (R29 scope).

## 회귀 리스크
- 5-tab 기반 UITest 다수 (리와인드/추억 접근) — 본 라운드에서 같이 수정.
- 기존 `fullScreenCover` on composer intercept 는 제거; FAB 에서 동일 cover 를 제시.
- `-UI_TEST_GROUP_STUB` / `-UI_TEST_AUTH_STUB` 플로우 동일하게 작동해야.
