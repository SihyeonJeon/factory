# Sprint 21 — Bottom Sheet 전체 화면 + 탭 구조

**Date:** 2026-04-14
**Source:** Human Feedback Round 3
**Goal:** 시트 최대화 = 전체 화면, "메인"/"보관함" 두 탭 구조

---

## Fix 1: 시트 최대화 = 전체 화면

In `Features/Home/MainBottomSheet.swift`:
- `MainSheetDetent.expanded.fraction`: `0.92` → `1.0`
- `topClearance` for `.expanded`: 이미 `0`이지만, SafeArea 포함하여 완전히 화면 덮도록
- 핸들: expanded 시 이미 숨김 처리 중 (확인)
- `.ignoresSafeArea(.all, edges: [.top, .bottom])` 이미 expanded에 적용 (확인)

---

## Fix 2: 시트 탭 구조 — "메인" + "보관함"

### 탭 정의

```swift
enum SheetTab: String, CaseIterable {
    case main = "메인"
    case archive = "보관함"
}
```

### 탭 바 UI
- 시트 핸들 바로 아래 (collapsed 제외)
- `HStack` with two tab buttons, 선택된 탭에 UnfadingTheme.primary 밑줄
- 44pt 최소 높이

### "메인" 탭 내용
- 기존 `defaultSheetContent` + `expandedSheetContent`의 내용
- 큐레이션/알고리즘 기반 추억 표시 (기존 로직 유지)
- 오늘의 되감기, 이벤트 섹션 등

### "보관함" 탭 내용
- 사진첩 형태 그리드 (LazyVGrid, 3열)
- 각 셀: 추억의 대표 사진 또는 감정 아이콘 + 장소명
- 시간 역순 정렬
- 셀 탭 → MemoryDetailView 네비게이션
- 사진이 없는 추억: 감정 아이콘 + 장소명 텍스트 카드

### 탭 상태
- `@State private var selectedSheetTab: SheetTab = .main`
- collapsed 상태에서는 탭 바 숨김
- defaultBrowsing/expanded에서 표시

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/MainBottomSheet.swift` | MODIFY — expanded fraction 1.0, 탭 바 슬롯 추가 |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — SheetTab 상태 추가, 탭 별 콘텐츠 분기, 보관함 그리드 |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥77).
- All new UI text in Korean.
- 44pt minimum touch targets.
- UnfadingTheme colors only.
- 보관함 그리드 셀에 `.accessibilityLabel` 필수.
