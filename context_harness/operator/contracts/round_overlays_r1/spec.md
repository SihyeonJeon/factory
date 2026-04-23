# round_overlays_r1 — GroupPickerOverlay + CategoryEditorOverlay

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only session)
**Dependencies:** R26–R29 완료 선행.

## Objective
zip README 섹션 "3. GroupPickerOverlay" + "4. CategoryEditorOverlay" 신규 UI 구현. TopChrome / FilterChipBar `+` 버튼에서 트리거. 기존 GroupStore (R18) 의 groups 배열과 ActiveGroupId state 활용.

## Authoritative Source
README 섹션 3 (그룹 선택) + 섹션 4 (카테고리 편집).

## Acceptance

### 1. GroupPickerOverlay
`workspace/ios/Features/Groups/GroupPickerOverlay.swift`:
- Full-frame modal. zIndex 200.
- Backdrop: `Color.black.opacity(0.28)` + `.blur(radius: 4)` behind. 외부 탭 → close.
- Card:
  - 폭 360, 라운드 24, `.shadow(style: UnfadingTheme.Shadow.overlay)`, `max-height: 80vh`.
  - Header: `"그룹 선택"` (sectionTitle) + `"여러 그룹을 동시에 쓸 수 있어요"` (body 12) + 우측 close(X) 34×34 surface.
  - List of groups (ScrollView):
    - 활성 그룹: `border 1.5px primary, background accentSoft`, 우측 체크 원 (primary 22pt).
    - 비활성: `border 0.5px divider, background card`.
    - 좌측: avatar stack (최대 3, `-10pt` 겹침, 2pt sheet 링) + `+N` 버블 (4명 이상).
    - 우측: 이름 + mode badge (`COUPLE` coral / `GROUP` mint) + `"\(N)명 · 함께한 지 \(X)일"` subline.
  - 맨 아래: `+ 새 그룹 만들기` 대시 버튼 (primary 66% opacity).
- Tap 비활성 그룹 → `GroupStore.setActive(id)` 호출 + scene reset (`MemoryMapHomeView` 가 초기 상태로 돌아감).
- Identifier: `group-picker-overlay`, 각 행 `group-picker-row-\(groupId)`, `group-picker-create`.

### 2. CategoryEditorOverlay
`workspace/ios/Features/Home/CategoryEditorOverlay.swift`:
- Full-frame modal. zIndex 201.
- Backdrop: 동일.
- Card:
  - Header: `"카테고리 편집"` + `"기본 · 추억 / 밥 / 카페 / 경험 · 직접 추가 가능"` (caption).
  - 기존 카테고리 리스트: 32×32 아이콘 배지 (`accentSoft + primary icon`) + 이름 + X 삭제.
  - 추가 블록: accentSoft 배경, `"새 카테고리"` label, TextField (placeholder `"예: 산책, 공연, 전시…"`) + "추가" 버튼. 아래 10개 아이콘 선택 (heart/bowl/cup/compass/mountain/sparkle/sun/camera/pin/yen).
  - 푸터: `"기본값"` (reset, surface 배경) + `"저장"` (primary CTA, flex 2:1 폭).
- 저장 시 `UserDefaults` 또는 `CategoryStore` 에 JSON 저장. 중복 이름 거절.
- 기본값 reset: [추억, 밥, 카페, 경험].

### 3. CategoryStore (신규)
`workspace/ios/Shared/CategoryStore.swift`:
- `@MainActor ObservableObject` with `@Published var categories: [Category]`.
- `Category { id: String (name), icon: String (iconName) }`.
- `load()` / `save()` via UserDefaults (key `unf.categories`).
- `reset()` → `[.memory, .meal, .cafe, .experience]` 기본값.
- `add(name:icon:)` throws duplicate.
- `remove(id:)`.

### 4. 연결
- `UnfadingTabShell` 에 `@State var showingGroupPicker = false, showingCategoryEditor = false`.
- TopChrome 전체 tap → `showingGroupPicker = true`.
- FilterChipBar `+` 버튼 → `showingCategoryEditor = true`.
- 두 overlay 는 `.overlay` 또는 `.fullScreenCover(isPresented:)` — 디자인상 backdrop blur 와 card 조합이라 `.overlay` + 자체 backdrop 구현이 선호.

### 5. UITest
- `testGroupPickerOpensFromTopChrome` — TopChrome tap → `group-picker-overlay` 존재 + close(X) tap → 사라짐.
- `testCategoryEditorOpensFromFilterPlus` — FilterChipBar `+` tap → `category-editor-overlay` 존재 + close → 사라짐.
- `testGroupPickerSwitchesActiveGroup` — 2개 이상 그룹 stub 상황에서 비활성 그룹 tap → activeGroupId 변경 (기존 TopChrome 그룹 이름 변화 확인).

### 6. 아티팩트
- `contracts/round_overlays_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_overlays_plan.md` (Challenge Section 본인 작성)
- `reports/round_overlays_r1/evidence/notes.md` — backdrop blur 결정, 2-overlay 동시 노출 금지 규칙, category duplicate 처리.

### 7. 빌드·테스트
- `xcodegen generate`
- `xcodebuild test -derivedDataPath .deriveddata/r30`
- 3 신규 UITest + 기존 전수 통과.

## Out of scope
- 새 그룹 생성 플로우 (R18 GroupOnboardingView 로 위임).
- 카테고리 per-memory 필터링 로직 고도화 (R31 composer scope).

## 회귀 리스크
- TopChrome tap 영역이 FilterChipBar 와 겹치지 않도록 주의.
- CategoryEditor 저장 시 기존 filterChip 선택 값이 삭제된 카테고리면 `"전체"` 로 reset.
