# Sprint 23 — 마커 클릭 → 시트 확장 + 클러스터 필터링

**Date:** 2026-04-14
**Source:** Human Feedback Round 3
**Goal:** 마커 탭 시 시트 자동 확장, 뒤로 가기 선택 해제, 클러스터 → 보관함 필터

---

## Fix 1: 마커 클릭 → 시트 자동 중간 확장

In `Features/Home/UnfadingHomeView.swift`:

### 현재:
- `onMarkerTap(memory)` → `activeMemoryID = memory.id` + 간략 보기 진입
- 시트 상태는 변경하지 않음

### 변경:
- `onMarkerTap` 핸들러에서 `mainSheetDetent = .defaultBrowsing` 추가
- 간략 보기 페이지 진입 로직 확인 — 없으면 `activeMemoryID` 설정 시 시트 내용이 해당 추억 카드로 변경되도록

---

## Fix 2: "선택 해제" → "뒤로 가기"

### 현재:
- `onClearSelection` 콜백으로 선택 해제 버튼 존재

### 변경:
- "선택 해제" 버튼 대신 네비게이션 "뒤로 가기" 패턴 사용
- `activeMemoryID`를 nil로 설정하는 것은 동일하되, UI에서는 `← 뒤로` 형태
- `.toolbar`에 `ToolbarItem(placement: .navigationBarLeading)` 사용
- 또는 시트 내 자체 뒤로 가기 버튼:

```swift
Button {
    clearSelection()
} label: {
    HStack(spacing: 4) {
        Image(systemName: "chevron.left")
        Text("뒤로")
    }
    .font(.system(.subheadline, design: .rounded))
}
.accessibilityLabel("뒤로 가기")
.accessibilityHint("추억 선택을 해제합니다.")
```

---

## Fix 3: 클러스터 마커 → 보관함 탭 필터링

### 현재:
- `onClusterTap(memories, title)` → 클러스터 내 추억 목록 표시

### 변경:
1. 클러스터 탭 시:
   - `selectedSheetTab = .archive` (보관함 탭으로 전환)
   - `clusterFilteredMemories = memories` (해당 클러스터 추억만 필터)
   - `mainSheetDetent = .defaultBrowsing` (시트 중간까지 확장)
2. 보관함에서 해당 추억만 그리드로 표시
3. 사진 셀 탭 → `MemoryDetailView`로 네비게이션

### 상태 추가:
```swift
@State private var clusterFilteredMemories: [DomainMemory]? = nil
// nil이면 전체 보관함, non-nil이면 클러스터 필터
```

### 클리어:
- "뒤로 가기" 또는 지도 배경 탭 시 `clusterFilteredMemories = nil`

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/UnfadingHomeView.swift` | MODIFY — 마커 탭 시 시트 확장, 뒤로 가기, 클러스터 필터 |
| `Features/Home/MainBottomSheet.swift` | MODIFY — onClearSelection을 뒤로 가기 UI로 변경 (필요 시) |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥77).
- All new UI text in Korean.
- 44pt minimum touch targets.
- UnfadingTheme colors only.
- Sprint 21의 SheetTab.archive와 연동 필수.
