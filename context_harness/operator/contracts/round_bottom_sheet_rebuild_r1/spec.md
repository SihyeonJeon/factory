# round_bottom_sheet_rebuild_r1 — BottomSheet 재작성 (탭바-above + 스크롤/드래그 분리 + ExpandedHeader)

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only session)
**Dependencies:** round_tabbar_shell_r1 완료 선행 (공통 root ZStack 구조).

## Objective
사용자 실기기 feedback-2 의 3개 블로커 해결:
1. Collapsed 시 탭바에 가림 → sheet bottom 을 탭바 위로 부유 (83pt 탭바 + 하단 여유).
2. 드래그로 최대화 불가 → Sprint 26 "시트 내부 스크롤 ↔ 드래그 분리" UIKit `UIScrollView` delegate bridge 구현.
3. Expanded 시 복귀 경로 없음 → `SheetExpandedHeader` fade-in + `←` back 버튼 + 위→아래 드래그 시 `default` 복귀.

## Authoritative Source
`docs/design-docs/unfading_ref/design_handoff_unfading/README.md` 의 "Bottom sheet", "Map Home — expanded state (Sprint 21)", "Interactions & Motion / 핵심 제약 (Sprint 26)".

## Acceptance

### 1. Snap 비율 (README 최신)
- `collapsed = 0.08`, `default = 0.50`, `expanded = 1.0`.
- `UnfadingTheme.Sheet` enum 이 R26 에서 이 값으로 바뀌어 있어야 함.

### 2. Sheet 바닥 위치
- Sheet bottom = 탭바 상단 = `UIScreen.main.bounds.height - 83pt - safeAreaBottom`.
- 즉 sheet 를 탭바 위에 띄움 (탭바 zIndex 120 에 가려지지 않음).
- `UnfadingTabShell` 내 root `ZStack(alignment: .bottom)` 구조를 활용.
- Sheet zIndex 50 (README).

### 3. Scroll/Drag 분리 (Sprint 26)
구현 방식: **UIKit UIScrollView delegate bridge** (Codex Challenge Section 권장).

- `workspace/ios/Shared/SheetScrollCoordinator.swift` (신규) — UIKit `UIScrollView` + `UIGestureRecognizer` 를 SwiftUI 로 연결.
- `UnfadingBottomSheet` 내용 영역을 `ScrollViewRepresentable` (`UIViewRepresentable`) 로 래핑.
- `scrollViewDidScroll(_:)` 에서:
  - `contentOffset.y <= 0` (top) 이고 추가 아래 드래그 velocity 면 **sheet snap 축소**.
  - 그 외에는 일반 스크롤.
- `scrollViewShouldScrollToTop(_:)` 는 기본 true.
- Sheet 드래그는 `UIPanGestureRecognizer` 를 scroll view 에 simultaneous 로 달아 handle 이 있을 때만 활성.

### 4. Drag gesture + nearest-snap + spring
- 손가락 translation 실시간으로 height 변경 (`@GestureState translation`).
- Release 시 velocity-projected nearest snap:
  - `projected = currentHeight - velocity.height * 0.2` (iOS standard projection)
  - `BottomSheetSnap.nearest(to: projected / frameHeight)` 로 스냅 결정
  - `.interpolatingSpring(stiffness: 260, damping: 32, initialVelocity: Double(velocity.height)/1000)` 애니메이션
- `reduceMotion` 시 `.easeInOut(duration: 0.25)` fallback.

### 5. Expanded 상태 (1.0)
- `cornerRadius = 0`, `shadow = .none`, `handle = hidden` (기존 R-feedback1 이 이미 구현했지만 재검증).
- **SheetExpandedHeader (신규)**: `workspace/ios/Features/Home/SheetExpandedHeader.swift`.
  - 구성: `← back / 그룹 pill (아바타 스택 + 이름) / 검색 필드` (horizontal).
  - `top 54pt safe area`, height 60, `background sheet` + `0.5px divider` 하단 경계, zIndex 55.
  - Opacity fade-in (220ms ease) 동기화.
- Back 버튼 tap 또는 scroll-top 에서 추가 아래 드래그 → `snap = .default` 복귀 + 역순 페이드.

### 6. Collapsed 요약
- `CollapsedSummary` — 핸들 아래 한 줄:
  - 커플: "우리의 추억 N · 위로 스와이프"
  - 일반 모임: "크루 기록 N · 위로 스와이프"
  - Font: `GowunDodum 11.5`.
- 전체 높이 = 8% 지만 탭바 위에 떠 있으므로 실질 UI 영역 약 67pt.

### 7. Handle
- 핸들: `42 × 5` rounded 3, `rgba(64,56,51,0.2)` (UnfadingTheme 토큰 `textPrimary.opacity(0.2)`).
- Expanded 시 `hidden` + `.accessibilityHidden(true)`.

### 8. FAB 동기화
R27 에서 만든 `ComposeFAB` 는 `sheetSnap == .expanded` 시 숨김 (opacity 0 + not hittable). Sheet binding 추가.

### 9. UITest
`UnfadingUITests.swift` 에 다음 보강 (기존 `testMapBottomSheetSnapGestures` 실패 원인 해결):
- `testSheetCollapsedHandleIsAboveTabBar` — collapsed 상태에서 handle 접근 가능 (탭바에 가리지 않음).
- `testSheetExpandedBackButtonReturnsToDefault` — expanded 진입 후 back 버튼 tap → default.
- `testSheetScrollDoesNotCollapseWhenNotAtTop` — expanded 상태에서 내부 스크롤 있으면 아래 스와이프해도 collapse 되지 않음 (내부 content scroll).

### 10. 재사용 자산
- 기존 `UnfadingBottomSheet` 재작성 (기존 struct name 유지, backward-compat).
- 기존 `BottomSheetSnap` enum 재사용.
- 새 `SheetScrollCoordinator` / `SheetExpandedHeader` 두 파일만 신규.

### 11. 아티팩트
- `contracts/round_bottom_sheet_rebuild_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_bottom_sheet_rebuild_plan.md` — Challenge Section.
- `reports/round_bottom_sheet_rebuild_r1/evidence/notes.md` — scroll bridge 구현 선택 이유 (SwiftUI-only vs UIKit), spring tuning 기록, 실기기 검증 체크리스트.

### 12. 빌드·테스트
- `xcodegen generate`
- `xcodebuild test` 완료까지.
- 최소 3 신규 XCUITest + 기존 테스트 전수 통과.

## Out of scope
- TopChrome/FilterChipBar/MapControls 좌표 (R29).
- Overlay (R30).
- Sheet 내부 콘텐츠 (큐레이션 카드, 이벤트 스트립 등) 상세 UI (R29 이후).

## 회귀 리스크
- 기존 `testMapBottomSheetSnapGestures` 실패 원인: gesture 시뮬레이터 타이밍. UIKit bridge 로 교체 시 재검증 필요.
- `-UI_TEST_SKIP_ONBOARDING` / `-UI_TEST_AUTH_STUB` / `-UI_TEST_GROUP_STUB` 조합이 collapsed summary 렌더링에 영향 없어야.
