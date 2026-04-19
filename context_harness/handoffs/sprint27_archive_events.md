# Sprint 27 — 보관함 이벤트별 그룹

## 목표
HF4 피드백 #5: 보관함에 이벤트(날짜)별 섹션 구분 추가.
현재: flat LazyVGrid (모든 추억이 동일 그리드에 나열)
목표: "제주도 데이트 (추억 5개)" → 사진 그리드, "경복궁 데이트 (추억 2개)" → 사진 그리드

## 현재 구조
- `archiveGridContent` (UnfadingHomeView.swift:730~): `clusterFilteredMemories` 전체를 하나의 LazyVGrid에 렌더링
- `MemorySheetGrouping.eventSections()` (MainBottomSheet.swift:13~): 이미 이벤트별 그룹핑 로직 존재. `EventMemorySection`으로 그룹화하여 `[EventMemorySection]` 반환

## 수정 계획
1. `archiveGridContent`에서 `clusterFilteredMemories`를 직접 사용하는 대신, `MemorySheetGrouping.eventSections(memories:events:)`로 그룹화
2. 각 `EventMemorySection`마다:
   - 섹션 헤더: 이벤트 제목 + 날짜 범위 + 추억 수
   - 3열 LazyVGrid with 기존 `archiveCell(for:)`
3. 이벤트 없는 추억은 날짜별 fallback 그룹으로 표시 (기존 로직이 이미 처리)

## 수정 대상 파일:
- Features/Home/UnfadingHomeView.swift (archiveGridContent 수정)

## 테스트:
xcodegen generate && xcodebuild test
