# Sprint 28 — 추억 상세 재구성

## 목표
HF4 피드백 #6: 추억 상세에서 이전/다음 동작 수정 + 설명 요소 재구성

## 현재 문제점
1. **이전/다음 버튼 미동작**: `navigator.moveToPrevious()` / `navigator.moveToNext()`는 `MemoryDetailNavigator.currentIndex`를 변경하지만, View는 `displayedMemory`를 사용하고 있음. `displayedMemory` computed property가 `navigator.currentMemory`를 올바르게 반환하는지 확인 필요.
2. **설명 요소가 약함**: 현재 메모, 이벤트, 비용, 감정 태그만 표시. 날씨, 코멘트, 방문 시간 등 추가 필요.

## 수정 계획

### 이전/다음 동작 수정
- `MemoryDetailView`의 `displayedMemory` computed property 확인
- `navigator` @StateObject가 init에서만 생성되므로 외부에서 memory가 바뀌어도 navigator가 업데이트되지 않을 수 있음
- 해결: navigator.currentMemory를 직접 body에서 사용하도록 수정

### 추억 상세 요소 재구성
1. **사진 섹션** (기존 유지)
2. **핵심 정보 카드**: 장소명, 날짜/시간, 이벤트명
3. **날씨 카드** (새로 추가): DomainMemory에 weather 필드 필요 → 없으면 UI만 준비하고 "날씨 정보 없음" 표시
4. **메모/코멘트 카드**: 기존 메모 + 편집 가능한 한줄 코멘트
5. **감정 태그** (기존 유지)
6. **비용** (기존 유지)
7. **리액션** (기존 유지)
8. **이전/다음 네비게이션**: 하단 고정, 현재 위치 표시 (3/7)

## DomainMemory 확장 (필요 시)
- `weather: String?` 필드 추가 (MemoryDomain.swift)
- 기존 테스트 호환성 유지 (기본값 nil)

## 수정 대상 파일:
- Features/Home/MemoryDetailView.swift (주요 수정)
- Shared/Domain/MemoryDomain.swift (weather 필드 추가 시)

## 테스트:
xcodegen generate && xcodebuild test
