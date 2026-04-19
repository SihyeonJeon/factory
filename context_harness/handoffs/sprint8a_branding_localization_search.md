# Sprint 8-A — App Branding ("Unfading") + Full Korean Localization + Search Bar

**Date:** 2026-04-13
**Source:** Human Feedback Round 1 — HF-1, HF-2, HF-4
**Goal:** Rebrand to "Unfading", convert ALL English UI text to Korean, add place search bar

---

## Task 1: Rebrand to "Unfading"

### What to change
- `project.yml`:
  - `name: MemoryMap` → `name: Unfading`
  - `PRODUCT_BUNDLE_IDENTIFIER: com.jeonsihyeon.memorymap` → `com.jeonsihyeon.unfading`
  - `INFOPLIST_KEY_CFBundleDisplayName: MemoryMap` → `Unfading`
  - Test target: `com.jeonsihyeon.memorymap.tests` → `com.jeonsihyeon.unfading.tests`
  - Scheme name: `MemoryMap` → `Unfading`
  - Target names: `MemoryMap` → `Unfading`, `MemoryMapTests` → `UnfadingTests`
- `App/MemoryMapApp.swift`:
  - Rename struct `MemoryMapApp` → `UnfadingApp`
  - Rename file → `UnfadingApp.swift`
- `Features/Home/MemoryMapHomeView.swift`:
  - `Text("Memory Map")` → `Text("Unfading")`
  - `Text("Browse your moments by place")` → `Text("우리의 흐려지지 않는 추억")`
  - Rename struct `MemoryMapHomeView` → `UnfadingHomeView`
  - Rename file → `UnfadingHomeView.swift`
- `Tests/MemoryMapTests.swift`:
  - Rename file → `UnfadingTests.swift`
  - Update `@testable import MemoryMap` → `@testable import Unfading`
  - Update class name if `MemoryMapTests` → `UnfadingTests`
- ALL other Swift files: update any `import MemoryMap` or reference to `MemoryMapHomeView` to new names
- `MEMORYMAP_EVIDENCE_MODE` env var key in MemoryMapApp.swift: keep as-is (internal, not user-facing)

### File rename mapping
| Old | New |
|---|---|
| `App/MemoryMapApp.swift` | `App/UnfadingApp.swift` |
| `Features/Home/MemoryMapHomeView.swift` | `Features/Home/UnfadingHomeView.swift` |
| `Tests/MemoryMapTests.swift` | `Tests/UnfadingTests.swift` |

---

## Task 2: Full Korean Localization (ALL UI text)

Convert every user-facing English string to Korean. Below is the comprehensive mapping. Apply to ALL files.

### Tab Bar (RootTabView.swift)
| English | Korean |
|---|---|
| `Label("Map", ...)` | `Label("지도", ...)` |
| `Label("Rewind", ...)` | `Label("되감기", ...)` |
| `Label("Groups", ...)` | `Label("그룹", ...)` |
| `"Map tab"` | `"지도 탭"` |
| `"Rewind tab"` | `"되감기 탭"` |
| `"Groups tab"` | `"그룹 탭"` |
| `"Browse memory pins..."` | `"지도에서 추억 핀과 장소 기록을 둘러봅니다."` |
| `"Review rewind moments..."` | `"되감기 모먼트와 알림 설정을 확인합니다."` |
| `"Create groups, join groups..."` | `"그룹을 만들고, 참여하고, 초대를 관리합니다."` |

### Home View (UnfadingHomeView.swift, formerly MemoryMapHomeView)
| English | Korean |
|---|---|
| `"Show current location"` | `"현재 위치 표시"` |
| `"Centers the map..."` | `"위치 권한이 있으면 지도를 현재 위치로 이동합니다."` |
| Any remaining English strings | Korean equivalent |

### Bottom Sheet (MainBottomSheet.swift)
| English | Korean |
|---|---|
| `"Bottom sheet handle"` | `"하단 시트 핸들"` |
| `"Clear Selection"` | `"선택 해제"` |
| `"Returns the sheet to the default browsing view."` | `"시트를 기본 탐색 보기로 되돌립니다."` |

### Memory Composer (MemoryComposerSheet.swift)
| English | Korean |
|---|---|
| `"Add a short note"` | `"짧은 메모 추가"` |
| `"Time"` | `"시간"` |
| `"Memory"` | `"추억"` |
| `"Event"` | `"이벤트"` |
| `"Attached event"` | `"연결된 이벤트"` |
| `"Create Event"` | `"이벤트 만들기"` |
| `"Create a group first..."` | `"먼저 그룹을 만드세요. 추억은 공유 그룹에 속하며 다른 멤버들이 볼 수 있습니다."` |
| `"Create a Group"` | `"그룹 만들기"` |
| `"Save"` | `"저장"` |
| `"Cancel"` | `"취소"` |
| `"New Memory"` | `"새 추억"` |
| `"Add from Library"` | `"라이브러리에서 추가"` |
| All other English text | Korean equivalent |

### Memory Detail (MemoryDetailView.swift)
| English | Korean |
|---|---|
| `"Note"` | `"메모"` |
| `"No note recorded."` | `"기록된 메모가 없습니다."` |
| `"Cost"` | `"비용"` |
| `"Emotion Tags"` | `"감정 태그"` |
| `"No emotion tags"` | `"감정 태그 없음"` |
| `"Reactions"` | `"리액션"` |
| `"Previous"` / `"Previous memory"` | `"이전"` / `"이전 추억"` |
| `"Next"` / `"Next memory"` | `"다음"` / `"다음 추억"` |
| `"Memory Detail"` | `"추억 상세"` |

### Memory Summary (MemorySummaryCard.swift)
| English | Korean |
|---|---|
| `"Adaptive"` | `"적응형"` |
| `"Newest first"` | `"최신순"` |
| `"Place-based"` | `"장소 기반"` |

### Curated Grouping (CuratedGrouping.swift)
| English | Korean |
|---|---|
| `"No memories yet"` | `"아직 추억이 없어요"` |
| `"Drop your first pin to start a grouping."` | `"첫 번째 핀을 찍어 그룹을 시작해보세요."` |

### HomeSummarySheet.swift
| All English strings | Korean equivalent |

### Group Hub (GroupHubView.swift)
| English | Korean |
|---|---|
| `"Groups"` | `"그룹"` |
| `"Create"` / `"New Group"` | `"만들기"` / `"새 그룹"` |
| `"Join"` | `"참여"` |
| `"Settings"` | `"설정"` |
| `"Delete"` | `"삭제"` |
| `"Edit"` | `"편집"` |
| `"Invite"` | `"초대"` |
| All other English text | Korean equivalent |

### Group Timeline (GroupTimelineView.swift)
| All English strings | Korean equivalent |

### Diary Cover (DiaryCoverCustomizationView.swift)
| All English strings | Korean equivalent |

### Map Theme / Pin Icon Pickers
| All English strings | Korean equivalent |

### Premium (PremiumUpgradeView.swift)
| English | Korean |
|---|---|
| `"Compare"` | `"비교"` |
| `"Map themes"` | `"지도 테마"` |
| `"Standard, Satellite, Hybrid"` | `"표준, 위성, 혼합"` |
| `"Muted, Dark, Vintage"` | `"뮤트, 다크, 빈티지"` |
| `"Advanced rewind"` | `"고급 되감기"` |
| `"Basic rewind"` | `"기본 되감기"` |
| `"Weekly digest"` | `"주간 다이제스트"` |
| `"Premium"` | `"프리미엄"` |
| `"Unlock custom map themes..."` | `"커스텀 지도 테마, 프리미엄 핀 팩, 고급 되감기를 잠금 해제합니다."` |
| `"Upgrade"` | `"업그레이드"` |
| `"Restore"` | `"복원"` |
| `"Close"` | `"닫기"` |
| `"Free"` | `"무료"` |

### Rewind views (RewindFeedView, RewindMomentCard, RewindSettingsView, YearEndReportView, YearlyRecapView)
| All English strings | Korean equivalent |

### Shared Domain files
| Any user-facing strings (error messages, display names) | Korean equivalent |

### project.yml permission descriptions
| English | Korean |
|---|---|
| `"Show nearby memory pins and place-based rewind moments."` | `"근처 추억 핀과 장소 기반 되감기 모먼트를 표시합니다."` |
| `"Deliver rewind moments when you return to meaningful places."` | `"의미 있는 장소에 돌아왔을 때 되감기 모먼트를 전달합니다."` |
| `"Save shared memory photos to your library."` | `"공유된 추억 사진을 라이브러리에 저장합니다."` |
| `"Attach photos to group memories."` | `"그룹 추억에 사진을 첨부합니다."` |
| `"Send rewind reminders and group updates."` | `"되감기 알림과 그룹 업데이트를 전송합니다."` |

### VoiceOver / Accessibility strings
- Translate ALL `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue` strings to Korean
- Keep `"Selected"` / `"Not selected"` / `"Requires Premium"` → `"선택됨"` / `"선택 안 됨"` / `"프리미엄 필요"`

---

## Task 3: Add Search Bar (통합 검색)

### 검색 대상
검색은 **세 가지**를 대상으로 한다:
1. **데이트 이름** — 그룹 내 이벤트/데이트 타이틀 (예: "홍대 데이트", "제주도 여행")
2. **추억명** — 각 Memory의 note 또는 title
3. **장소명** — Memory에 연결된 place.title (있는 경우)

지도 API를 통한 외부 장소 검색은 하지 않는다. 앱 내 데이터만 검색한다.

### UI 위치 및 스타일
In `UnfadingHomeView.swift` (formerly MemoryMapHomeView):
- `topHeader`의 기존 "Memory Map" 배너를 다음으로 교체:
  1. `Text("Unfading")` 앱 타이틀 (`.title3.weight(.bold)`)
  2. 그 아래 검색 바: `TextField("데이트, 추억 검색", text: $searchQuery)` + 돋보기 아이콘
- 스타일: 둥근 모서리(`RoundedRectangle(cornerRadius: 12)`), 연한 배경(`.fill(.ultraThinMaterial)` 또는 `.gray.opacity(0.12)`), leading에 `magnifyingglass` 아이콘, trailing에 X 클리어 버튼

### 자동완성 (Autocomplete)
- `@State private var searchQuery = ""` 프로퍼티 추가
- 글자를 입력하는 즉시 검색 결과가 검색 바 하단에 리스팅됨
- 결과 리스트는 두 섹션으로 구분:
  - **"데이트"** 섹션: 매칭되는 이벤트/데이트 이름 목록
  - **"추억"** 섹션: 매칭되는 추억(Memory) 목록 (note/title + 장소명 표시)
- case-insensitive 매칭, 부분 문자열 검색
- 결과가 없으면 "검색 결과 없음" 표시
- 검색 결과 리스트는 맵 위에 오버레이로 표시 (반투명 배경)

### 검색 결과 선택 동작

#### 데이트 선택 시:
1. 검색 바 닫힘 (searchQuery 클리어)
2. **바텀 시트**: 해당 데이트에 속한 추억들만 필터링하여 표시
3. **지도**: 해당 데이트의 모든 추억 마커가 보이도록 map region을 자동 조정 (fit to markers)
4. **마커**: 해당 데이트 내의 모든 마커가 선택 상태로 표시

#### 추억 선택 시:
1. 검색 바 닫힘 (searchQuery 클리어)
2. 즉시 **추억 간략히 보기** 페이지로 이동 (바텀 시트 중간 스냅에서 해당 추억 표시)
3. 지도가 해당 추억의 좌표로 이동 + 마커 선택

### 필요한 상태 관리
- `@State private var searchQuery: String = ""`
- `@State private var isSearchActive: Bool = false`
- `@State private var dateFilter: String? = nil` — 선택된 데이트 이름으로 필터링 (nil이면 전체)
- 필터가 활성화되면 바텀 시트 상단에 "X {데이트이름}" 필터 칩 표시, X 누르면 필터 해제

---

## Task 4: Update Tests

- All test imports: `@testable import Unfading`
- All references to renamed structs must be updated
- Tests must still compile and pass (target: 75 tests)

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All tests must pass.
- Do NOT miss any English string. Search every `.swift` file for remaining English text after conversion.
- Keep struct/file naming consistent: if file is renamed, update ALL references across ALL files.
