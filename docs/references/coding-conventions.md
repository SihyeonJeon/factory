# Coding Conventions — Unfading iOS

**Date:** 2026-04-14
**Authority:** 모든 에이전트는 이 규칙을 따른다.

---

## 1. 아키텍처 계약

### Store 패턴 (입출력 계약)
```swift
// 모든 Store는 이 계약을 따른다
@MainActor
final class XxxStore: ObservableObject {
    @Published private(set) var items: [DomainXxx]  // 읽기 전용 외부 노출
    
    func add(_ item: DomainXxx)      // 입력: 도메인 모델 → 부수효과: items 갱신
    func remove(id: UUID)            // 입력: ID → 부수효과: items에서 제거
    func loadSampleDataIfNeeded()    // 입력: 없음 → 부수효과: 빈 상태면 샘플 로드
}
```

**계약:** `@Published private(set)` — 외부는 읽기만, 변경은 Store 메서드를 통해서만.

### Domain Model 계약
```swift
struct DomainXxx: Identifiable, Codable, Equatable {
    let id: UUID          // 불변 식별자
    var mutableField: T   // 변경 가능 필드는 var
}
```

### View 계약
```swift
struct XxxView: View {
    // 1. @EnvironmentObject — 앱 전역 상태 (Store, Router)
    // 2. @StateObject — 이 View가 소유하는 로컬 상태 객체
    // 3. @State — 이 View의 로컬 UI 상태
    // 4. let properties — 부모로부터 주입받은 불변 데이터
    // 5. @Binding — 부모와 양방향 바인딩
}
```

### Service 계약
```swift
@MainActor
final class XxxService: ObservableObject {
    @Published var results: [T]         // 결과 (외부 읽기)
    @Published var isLoading: Bool      // 로딩 상태
    
    func search(query: String)          // 입력 → 부수효과: results 갱신
    func cancel()                       // 진행 중 작업 취소
}
```

---

## 2. 네이밍 규칙

| 종류 | 패턴 | 예시 |
|------|------|------|
| Domain model | `Domain` + 명사 | `DomainMemory`, `DomainGroup` |
| Store | 명사 + `Store` | `MemoryStore`, `GroupStore` |
| Service | 명사 + `Service` | `PlaceSearchService` |
| View | 기능명 + `View` | `CalendarView`, `SettingsView` |
| Sheet | 기능명 + `Sheet` | `MemoryComposerSheet` |
| Marker | 기능명 + `Marker` | `MemoryPinMarker` |
| Theme | `UnfadingTheme.` + 속성 | `UnfadingTheme.primary` |
| Enum | PascalCase, CaseIterable | `EmotionTag`, `MapTheme` |

---

## 3. 스타일 규칙

### 색상
```swift
// ✅ 허용
UnfadingTheme.primary
UnfadingTheme.textPrimary
UnfadingTheme.cardBackground

// ❌ 금지
Color.red
Color(red: 0.5, green: 0.3, blue: 0.2)  // inline 색상
.foregroundColor(.blue)
```

### 폰트
```swift
// ✅ 허용 — semantic styles
.font(.system(.footnote, design: .rounded))
.font(.subheadline.weight(.semibold))
@ScaledMetric(relativeTo: .title) var iconSize = 24

// ❌ 금지 — hardcoded sizes
.font(.system(size: 14))
.font(.custom("Helvetica", size: 16))
```

### 접근성
```swift
// ✅ 모든 interactive element에 필수
.accessibilityLabel("한국어 레이블")
.accessibilityHint("한국어 힌트")
.frame(minWidth: 44, minHeight: 44)
.contentShape(Rectangle())

// ❌ 금지 — 접근성 없는 interactive element
Button { } label: { Image(systemName: "xmark") }  // label 없음
```

### UI 텍스트
```swift
// ✅ 모든 사용자 대면 텍스트는 한국어
Text("추억 추가")
.accessibilityLabel("현재 위치 표시")

// ❌ 금지
Text("Add Memory")
.accessibilityLabel("Show current location")
```

---

## 4. 금지 영역 (FORBIDDEN)

### 절대 금지
| 규칙 | 이유 |
|------|------|
| `mapView.showsUserLocation = true` 무조건 설정 | MKMapView가 자동으로 위치 권한 요청 |
| `PHAsset.fetchAssets()` 권한 확인 없이 호출 | Photos 전체 접근 다이얼로그 트리거 |
| `.font(.system(size: N))` | Dynamic Type 위반 → HIG BLOCKER |
| inline `Color()` 사용 | UnfadingTheme 드리프트 |
| `@StateObject` Store를 여러 View에서 각각 생성 | 상태 불일치 — `@EnvironmentObject`로 공유 |
| Self-approval (작성자 = 검증자) | 자기 과대평가 방지 원칙 위반 |
| `extract_blockers()` boolean만 신뢰 | regex 오탐 알려진 패턴 |
| 영어 UI 텍스트 | 한국어 전용 앱 |
| `.preferredColorScheme` 제거 | 다크모드 미구현 상태에서 제거 시 UI 깨짐 |

### 조건부 허용
| 규칙 | 조건 |
|------|------|
| 새 파일 추가 | brief 파일 목록에 명시 필수 |
| `#Preview` 블록 | production 코드에 영향 없어야 함 |
| `canImport()` 가드 | SDK 미추가 모듈에만 사용 |

---

## 5. 파일 구조 계약

```
workspace/ios/
├── App/           → @main, TabView, 앱 레벨 환경 주입
├── Features/      → 화면별 View + 관련 컴포넌트
│   ├── Home/      → 지도, 시트, 마커, 갤러리, 컴포저
│   ├── Calendar/  → 캘린더, 월 그리드, 일별 목록
│   └── Settings/  → 설정
├── Shared/        → 앱 전역 공유 모듈
│   ├── Domain/    → DomainModel, Store, enum (비즈니스 로직)
│   └── *.swift    → Service, Theme, Utility (UI 지원)
└── Tests/         → 단위 테스트
```

**규칙:** 새 Feature 추가 시 `Features/` 하위에 디렉토리 생성. Shared에는 2개 이상 Feature에서 사용되는 것만.

---

## 6. 권한 요청 계약

```
권한 요청 = 사용자 제스처에 의해서만 트리거 (위치 제외)
위치 권한 = 앱 시작 시 자동 요청 (HF3 피드백 반영, 2026-04-14)
```

| 권한 | 트리거 시점 | 파일 |
|------|------------|------|
| 위치 | 앱 시작 시 `.task` | LocationPermissionStore |
| 사진 | PhotosPicker 사용 시 | MemoryComposerSheet |
| 알림 | 리마인더 설정 시 | RewindReminderStore |
| 카메라 | 카메라 버튼 탭 시 | (미구현) |
