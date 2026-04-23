# round_home_chrome_r1 — Home chrome 정확 좌표 + zIndex

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only session)
**Dependencies:** R26 (tokens), R27 (tab shell), R28 (sheet + shell binding) 완료 선행.

## Objective
zip README "Global Layout System / 고정 z-레이어" + "1. Map Home — default" 섹션에 따라 **TopChrome, FilterChipBar, MapControls, FAB** 의 좌표/크기/zIndex/모션 을 픽셀 단위로 일치시킴. 마커 클릭 → `map-selected` 전이 시 visual 차이 반영.

## Authoritative Source
`docs/design-docs/unfading_ref/design_handoff_unfading/README.md` 섹션:
- "고정 z-레이어 (요구 사항)"
- "1. Map Home — default / Top chrome / Filter chip bar / Map controls / FAB"
- "State Model / 상태 전이 규칙" (snap==.expanded 시 chrome fade-out)

## zIndex 정확 적용
- 지도 marker: **10**
- MapControls: **26**
- FilterChipBar: **28**
- TopChrome: **30**
- BottomSheet: **50**
- SheetExpandedHeader: **55**
- FAB: **70**
- TabBar: **120** (R27 기완료)
- 모달 (GroupPicker/CategoryEditor): 200+ (R30)

현재 값과 일치 여부 전수 확인 후 불일치 수정.

## Acceptance

### 1. TopChrome
- 위치: `top: 54pt, leading: 16pt, trailing: 16pt` → `UnfadingTheme.Spacing.md = 16` 사용.
- 배경: `sheet 94%` + `blur(24)`. 라운드 `18`, border `0.5px divider`, shadow `card`.
- 좌측 avatar stack (최대 3). 커플 모드는 중앙 heart overlay (Heart pin 심볼).
- 중앙:
  - 커플 copy: `"함께한 지 \(N)일"`
  - 일반 모임 copy: `"\(members.count)명 · 함께한 지 \(N)일"`
  - Font: `GowunDodum 15/700/-0.2` via `UnfadingTheme.Font.sectionTitle(15)`.
- 우측 search 아이콘 버튼 32×32, surface 배경.
- 전체 클릭 → `onSwitchGroup()` (R30 GroupPickerOverlay 호출 스텁. 지금은 `onSwitchGroup` 콜백만 노출).
- zIndex 30.
- `snap != .expanded` 시에만 렌더.

### 2. FilterChipBar
- 위치: `top: 108pt` (TopChrome 54 + 높이 + 간격).
- 좌→우 가로 스크롤 `ScrollView(.horizontal)`.
- 첫 칩 `전체` (sparkle). 이후 사용자 카테고리 리스트. 마지막 `+` 점선 버튼 → `CategoryEditorOverlay` (R30).
- 기본 카테고리 배열 (프로토타입 명시): `추억(heart) · 밥(bowl) · 카페(cup) · 경험(compass)`.
- 활성 chip: `background primary, color #fff, shadow 0 2px 8px rgba(245,153,140,0.35)`.
- 비활성 chip: `background sheet, color textPrimary, border 0.5px divider`.
- 칩 font `UnfadingTheme.Font.chip(13)` weight 700 (GowunDodum 단일 weight 라 size 로 강조).
- zIndex 28.
- `snap != .expanded` 시에만 렌더.

### 3. MapControls
- 위치: `right: 16pt, bottom: sheet.maxY + 20pt`.
- 두 버튼 수직 스택, 간격 8pt.
- 각 버튼 40×40 circle, `background sheet 94% + blur(24)`, shadow `0 2px 8px rgba(0,0,0,0.10)`.
- 위: `locationFill` (현재 위치). Tap → `scale(0.92) pulse` (120ms).
- 아래: `northArrow` (heading 0° 복원).
- zIndex 26.
- `snap != .expanded` 시에만 렌더.

### 4. FAB (ComposeFAB, R27 기완료)
- 위치: `right: 18pt, bottom: sheet.maxY + 18pt`.
- 56×56 circle, `primary → primaryHover` gradient. `+` 아이콘.
- `activeCard` shadow.
- zIndex 70.
- Tap → composer `fullScreenCover` (R27 shell 레벨).
- `snap != .expanded` 시에만 visible (R28 기완료, 재검증).
- Press: `scale(0.96)` (120ms ease).

### 5. Chrome fade (Sprint 21)
`snap == .expanded` 전환 시:
- TopChrome / FilterChipBar / MapControls / FAB **모두 opacity 0 → 1 역전** 220ms ease.
- SheetExpandedHeader 는 fade-in (R28 기완료).
- 복귀 시 역순.
- 구현: `sheetSnap` binding 기반 `.opacity(sheetSnap == .expanded ? 0 : 1).animation(.easeInOut(duration: 0.22), value: sheetSnap)`.

### 6. 마커 선택 시 (Sprint 23)
- `scene == 'map-selected'` (marker 클릭) 시:
  - 비선택 마커 `opacity 0.4` 희미.
  - 선택 마커 `scale 1.15` + halo.
  - sheet 는 `default` 로 자동 전환 (기존 MemorySelectionState 활용).
- 현재 마커 렌더링 로직 확인 후 opacity 조정.

### 7. UITest
- `testHomeChromeLayoutCoordinates` — TopChrome / FilterChipBar / MapControls 의 `frame.minX/Y/width/height` 가 기대값 허용 범위 (±2pt) 내인지.
- `testChromeFadesOnExpanded` — collapsed→expanded 제스처 대신, UI 테스트에서 `-UI_TEST_SHEET_SNAP=expanded` 런치 argument 로 초기 스냅을 expanded 로 강제. TopChrome/FilterChipBar element 가 not hittable/invisible.
- **simulator gesture 불안정 자체는 건드리지 않음.**

### 8. 추가 launch argument
`MemoryMapApp.swift` / `UnfadingTabShell.swift`:
- `-UI_TEST_SHEET_SNAP=<collapsed|default|expanded>` 인식 시 초기 sheet snap 을 해당 값으로 강제.
- 이 flag 는 UITest 에서만 사용 (prod 영향 없음).

### 9. 아티팩트
- `contracts/round_home_chrome_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_home_chrome_plan.md` (Challenge Section 본인 작성)
- `reports/round_home_chrome_r1/evidence/notes.md` — 측정값, diff 전/후, zIndex 전수표, marker 선택 시 opacity 결정 근거.

### 10. 빌드·테스트
- `xcodegen generate`.
- `xcodebuild test` 전수 통과.
- 신규 2 UITest 추가.

## Out of scope
- 마커 클러스터링 (별도 sprint). 기본 파란 pin 유지.
- 사진/이벤트 카드 UI (R29 아닌 기존 R-feedback1 수준 유지).
- Composer/Calendar/Settings (Phase 2).

## 회귀 리스크
- TopChrome 의 blur background 는 성능 영향. 시뮬레이터에서 FPS 저하 시 `Material` 대신 단색 fallback 고려.
- zIndex 변경이 기존 FAB/sheet 드래그 경로 충돌 가능. 테스트로 확인.

## 측정/검증 수치
| Element | 기대 frame.origin | 기대 size |
|---|---|---|
| TopChrome | x=16, y=54 | 358 × ~60 |
| FilterChipBar | x=0, y=108 | screenW × 32 |
| MapControls stack | x=screenW-56, y=sheet.maxY-110 (88+20) | 40 × 88 |
| FAB | x=screenW-74, y=sheet.maxY-74 (56+18) | 56 × 56 |
