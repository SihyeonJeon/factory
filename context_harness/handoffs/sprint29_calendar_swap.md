# Sprint 29 — 캘린더 계획 + 모임 스왑

## 목표
HF4 피드백 #7: 캘린더에 계획 기능 추가
HF4 피드백 #8: 모임 간편 스왑 (지도/보관함 연동)

## Fix 1 — 캘린더 계획 기능 (#7)
현재 캘린더는 추억(과거)만 표시. 미래 일정/계획도 표시할 수 있어야 함.

### 수정 계획
1. `DomainEvent`에 `isPlanned: Bool` 또는 미래 날짜 이벤트를 자동으로 "계획"으로 취급
2. 캘린더 그리드에 계획 날짜 표시 (다른 색상 마커 — e.g., UnfadingTheme.accent)
3. 날짜 탭 시 DayMemoriesList에 계획 이벤트도 표시
4. 계획 추가 버튼 (간단한 제목 + 날짜 입력)

### 수정 대상 파일
- Features/Calendar/DayMemoriesList.swift
- Features/Calendar/MonthlyCalendarGrid.swift
- Shared/Domain/MemoryDomain.swift (DomainEvent 확장 또는 DomainPlan 추가)

## Fix 2 — 모임 간편 스왑 (#8)
현재 모임(Group) 변경이 불편함. 간편 스왑 UI 필요.

### 수정 계획
1. 시트 상단 또는 지도 상단에 현재 모임명 표시 (탭 가능)
2. 탭 시 모임 목록 popover/sheet — 각 모임에 아이콘/이름/멤버 수
3. 모임 선택 시 `groupStore.selectGroup(id:)` → 지도 마커, 보관함, 갤러리 모두 해당 그룹 필터링
4. UI 테마도 그룹별로 다르면 적용 (pinPack 등)

### 수정 대상 파일
- Features/Home/UnfadingHomeView.swift (그룹 스왑 UI + 필터링)
- Shared/Domain/GroupStore.swift (selectedGroupID 관리)

## 테스트:
xcodegen generate && xcodebuild test
