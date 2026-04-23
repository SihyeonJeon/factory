# Handoff: Unfading — Private Map Diary (iOS)

> 이 번들은 HTML로 만든 **디자인 레퍼런스**입니다. 그대로 배포할 코드가 아니라, 실제 코드베이스(SwiftUI가 1차 타깃 / 전환기에 React Native도 허용 — `SihyeonJeon/factory` `constraints.md` 기준)에 **재현해야 할 시각·동작 명세**로 봐주세요. 기존 환경이 없다면 SwiftUI로 구현합니다.

## Overview

**Unfading (흐려지지 않는)** — 커플/반복 모임이 함께 간 장소를 지도 위에 사진·일기로 기록하는 사적(私的) 지도 다이어리. "언제 어디서 우리가 무엇을 했는지"가 흐려지지 않도록 보관하는 것이 제품의 핵심이고, 소셜 피드/공개성은 의도적으로 배제합니다. 커플 모드(2명)와 일반 모임 모드(N명)를 같은 앱이 지원하며, 한 사용자가 **여러 그룹**을 동시에 소유할 수 있습니다.

### 이 프로토타입이 다루는 범위
- 홈(지도 + 하단 시트 2탭)
- 그룹 선택 모달 / 카테고리 편집 모달
- 추억 상세
- 새 추억 작성(Composer) — 커플/모임 분기 포함
- 캘린더 (다이얼 네비 + 일반 모임 계획 기능)
- Rewind (월/연 요약 풀스크린 카드)
- 그룹 허브 (설정)

### 이 프로토타입이 다루지 않는 범위
- 실제 지도 타일(MapKit/Google Maps) — placeholder SVG로 대체됨
- 실제 사진 EXIF 파싱 — 텍스트로만 시뮬레이션
- Apple Sign-in, iCloud 동기화, 결제, 테마 구매 구체 구현
- 멀티피드/댓글 — 본 프로토타입에 포함되긴 하지만 UI 초안 수준

## Fidelity

**High-fidelity (hifi).** 색상·타이포그래피·여백·라운드·섀도·인터랙션까지 최종 안에 가깝게 정의되어 있습니다. 구현 시 토큰 값은 그대로 따르고, 레이아웃은 SwiftUI의 표준 컴포넌트(`NavigationStack`, `BottomSheet(presentationDetents)`, `Map`, `LazyVGrid` 등)에 매핑하세요.

## About the Design Files

- `prototype/Unfading Prototype.html` — 단일 파일 React+Babel 프로토타입. 모든 화면이 한 파일에 인라인으로 묶여 있습니다. 섹션 구분은 `// ===== <name>.jsx =====` 주석 블록으로 되어 있음.
- 파일은 iPhone 프레임 안에 렌더링되며, 좌측 '씬 스위처'로 화면 간 직접 이동 가능.
- 상단 툴바의 **Tweaks** 토글을 켜면 모드(couple / general_group), 지도 테마(default/warm/mono), 기본 시트 높이 등을 실시간으로 조작할 수 있습니다.

## 원본 제품 문서 (출처)

구현 시 반드시 같이 참고해야 하는 문서들 — `SihyeonJeon/factory` 레포의 `context_harness/`에 존재:

- `product_inputs/idea.md` — 한 줄 정의, 원칙, "흐려지지 않는" 메타포
- `product_inputs/design.md` — 톤, 색, 폰트 의도
- `product_inputs/constraints.md` — 플랫폼/성능/스코프 제약
- `prd/ui_ux_screen_contract.md` — 화면 단위 계약
- `handoffs/sprint8b_design_tone.md` — 커플 감성 디자인 톤 전면 개편
- `handoffs/sprint12_tab_redesign.md` — 하단 탭/캘린더/시트 모션
- `handoffs/sprint13_photos_clusters.md` — 사진 표시 + 클러스터 마커
- `handoffs/sprint14_location_placesearch.md` — 위치 권한 + 장소 검색
- `handoffs/sprint21_sheet_tabs.md` — 시트 전체화면 + 탭 구조
- `handoffs/sprint22_calendar_dial.md` — 캘린더 다이얼 + 시간 다이얼
- `handoffs/sprint23_marker_interaction.md` — 마커 클릭 → 시트 확장 + 필터링
- `handoffs/sprint26_sheet_fixes.md` — 시트 스크롤/모션 수정
- `handoffs/sprint27_archive_events.md` — 보관함 이벤트별 그룹
- `handoffs/sprint28_detail_redesign.md` — 추억 상세 재구성
- `handoffs/sprint29_calendar_swap.md` — 캘린더 계획 기능 + 모임 스왑

프로토타입의 인터랙션은 위 핸드오프 문서들을 종합 반영한 것입니다. 구현 규칙이 충돌할 경우 **최신 sprint 문서 + 본 README**가 우선합니다.

---

## Design Tokens

모두 프로토타입 최상단 `const THEME`에서 실제 사용 중인 값입니다.

### Color (warm couple palette, Sprint 8-B)
| Token            | Hex        | 용도 |
| ---------------- | ---------- | ---- |
| `bg`             | `#FFF8F0`  | 전체 앱 배경 / 상태바 뒤 |
| `sheet`          | `#FFFBF5`  | 바텀시트·카드 기본 배경 |
| `card`           | `#FFFFFF`  | 컨텐츠 카드 |
| `surface`        | `#F5EEE4`  | 세그먼트/칩 비선택 배경 |
| `primary`        | `#F5998C`  | 메인 코럴 — CTA, 활성 탭, 마커 강조 |
| `primaryHover`   | `#E8877A`  | 누름 상태 |
| `accentSoft`     | `#FAE4DD`  | 액션 배지 배경 (쿠 pill) |
| `secondary`      | `#8FB7A8`  | 세컨더리 민트 — 모임 배지, 식물/경험 태그 |
| `secondaryLight` | `#CDE2DA`  | 보조 배경 |
| `textPrimary`    | `#403833`  | 기본 텍스트 (검정 대신 따뜻한 다크브라운) |
| `textSecondary`  | `#8C827A`  | 보조 텍스트 |
| `textTertiary`   | `#B8AEA5`  | 3차 / 비활성 |
| `divider`        | `#EBE1D4`  | 0.5px 구분선 |
| `chipBg`         | `#F5EEE4`  | 해시태그/칩 비활성 |
| `mapBase`        | `#FFF3E6`  | 지도 placeholder 기본색 |
| `mapLand`        | `#FFE8D1`  | 지도 land |
| `mapWater`       | `#DCE7E4`  | 지도 water |
| `mapRoad`        | `#F5EEE0`  | 지도 도로 |

Member color palette (아바타):
`#F5998C` (coral) · `#E4B978` (amber) · `#8FB7A8` (mint) · `#A9A1C7` (lavender) · `#7B9FD4` (blue) · `#D48FB2` (rose) · `#C7A77B` (camel) · `#9A85C0` (violet) · `#7BAFB1` (teal) · `#8FA88B` (sage).

### Radius
`cardRadius: 18`, `sheetRadius: 28`, 칩 18, 세그먼트 12.

### Shadow
- 기본 카드: `0 2px 6px rgba(64,56,51,0.04)`
- 활성 카드/CTA: `0 4px 12px rgba(245,153,140,0.40)`
- 오버레이 모달: `0 20px 60px rgba(64,56,51,0.25)`
- 탭바 상단 경계: `0.5px solid #EBE1D4`

### Typography
두 폰트 스택만 사용 — 한국어 본문은 **Gowun Dodum**, 숫자·영문·메타는 **Nunito**. 두 폰트는 Google Fonts에서 로드 (`Gowun+Dodum`, `Nunito:wght@400;500;600;700;800`).

| 역할 | Family | Size | Weight | Letter |
| --- | --- | --- | --- | --- |
| 화면 큰 제목 | Gowun Dodum | 20–22 | 700 | -0.3 |
| 섹션 타이틀 | Gowun Dodum | 15–16 | 700 | -0.2 |
| 본문 | Gowun Dodum | 13.5–14.5 | 500–600 | 0 |
| 칩/버튼 | Gowun Dodum | 12–13 | 700 | 0 |
| 메타 / 숫자 | Nunito | 10.5–12 | 700–800 | 0.5 (uppercase만) |
| 태그 (`#...`) | Gowun Dodum | 10.5 | 500 | 0 |

SwiftUI 매핑: `.custom("GowunDodum-Regular", size: ...)` / `.custom("Nunito-Bold", size: ...)`. 시스템 폰트 폴백은 허용하지 말 것 — 톤이 크게 달라짐.

### Spacing scale (px)
4 / 6 / 8 / 10 / 12 / 14 / 16 / 18 / 20 / 24 / 28 / 30 / 80(시트 하단 여유) / 110(탭바 대비 여유).

### Icon set
1.8~2.2 stroke의 모노 라인 아이콘. 프로토타입의 `Icon` 컴포넌트에 정의된 이름들: `search, calendar, sparkle, heart, heartFill, bookmark, bookmarkFill, chevronR, chevronL, chevronD, plus, close, pin, map, camera, people, clock, yen, trend, sun, moon, mountain, image, star, bowl, cup, compass, locationFill, northArrow, settings, back, archive`. SwiftUI는 SF Symbols 중 가장 가까운 심볼 사용 + weight 조절. 커스텀이 꼭 필요한 심볼은 `bowl`(밥), `cup`(카페), `compass`(경험) — SF Symbols의 `fork.knife`, `cup.and.saucer`, `safari` 로 매핑 가능.

---

## Global Layout System

### 화면 사이즈
iPhone 15/16 논리 크기: **390 × 844 pt**. safe top 54 pt (Dynamic Island), safe bottom 34 pt. 모든 고정 좌표는 이 기준으로 설계됨.

### 고정 z-레이어 (요구 사항)
- 지도 및 마커: 10
- 맵 컨트롤(위치/나침반 FAB): 26
- 그룹 배너(TopChrome): 30
- 카테고리 칩바(FilterChipBar): 28 — 배너 바로 아래 `top: 108`
- FAB(새 추억): 70
- 바텀 시트: 50
- 시트 전체확장 상태의 상단 merged bar (ExpandedHeader): 55
- 하단 iOS TabBar: **120** (캘린더/설정 풀스크린 화면 위에도 항상 보이도록)
- 모달(그룹 선택, 카테고리 편집, 공유, 타이머): 200~10000

### 전역 페이지 구조
```
IOSFrame
 ├─ MapLayer                 (scene.startsWith('map-') 일 때)
 ├─ TopChrome                (snap ≠ expanded 일 때만)
 ├─ FilterChipBar            (snap ≠ expanded 일 때만)
 ├─ MapControls              (위치/나침반, snap ≠ expanded 일 때만)
 ├─ BottomSheet              (3-snap: collapsed / default / expanded)
 │    ├─ collapsed: 핸들 + 한 줄 요약만 (height ≈ 8%)
 │    ├─ default:   큐레이션/보관함 탭 + 기본 콘텐츠 (≈ 50%)
 │    └─ expanded:  풀스크린처럼 상단 merged bar + 스크롤 (≈ 100%)
 ├─ FAB (+)                  (snap ≠ expanded, 스코프: map only)
 ├─ IOSTabBar                (항상 — 지도/캘린더/설정)
 ├─ GroupPickerOverlay       (groupPickerOpen=true)
 └─ CategoryEditorOverlay    (catEditorOpen=true)
```

---

## State Model

프로토타입의 App 컴포넌트 기준.

```ts
type Scene =
  | 'map-default' | 'map-selected'
  | 'detail' | 'composer' | 'calendar' | 'rewind' | 'group';

type Tab = 'map' | 'calendar' | 'settings';

type SheetSnap = 'collapsed' | 'default' | 'expanded';

type Mode = 'couple' | 'general_group';

interface AppState {
  scene: Scene;                // 현재 메인 화면
  tab: Tab;                    // iOS 하단 탭
  snap: SheetSnap;             // 바텀시트 스냅
  markerId: string | null;     // 지도에서 선택된 마커
  memoryId: string;            // 상세 열릴 때 대상
  filterChip: string;          // '전체' | 카테고리 id
  sheetTab: 'curated' | 'archive';
  activeGroupId: string;       // 현재 활성 그룹
  groupPickerOpen: boolean;
  categories: Category[];      // 사용자가 편집 가능
  catEditorOpen: boolean;
  tweaks: TweakValues;         // 디자인 튜닝 (아래)
}
```

### localStorage 키 (프로토타입에서 실제로 사용)
- `unf.scene` — 마지막 씬 복원
- `unf.group` — 마지막 활성 그룹
- `unf.cats` — 사용자 카테고리 리스트(JSON)
- `unf.tweaks` — Tweaks 값 (옵션)

실제 앱에서는 UserDefaults(SwiftUI) 또는 동등한 영속 저장소에 대응.

### 상태 전이 규칙
- 마커 클릭 → `setScene('map-selected'); setMarkerId(id); snap → 'default'`
- 마커의 닫기(X) → `scene → 'map-default'; markerId = null; snap 유지`
- 시트를 위로 스와이프 → `snap: collapsed → default → expanded`
- `expanded` 도달 순간 TopChrome / FilterChipBar / MapControls / FAB 가 **페이드아웃** (220ms ease)되고 ExpandedHeader 가 **페이드인**. 핸들은 `expanded`일 때 숨김.
- 시트 내부에서 아래로 당기면 (스크롤 top에서 추가 드래그) `expanded → default` 로 축소.
- TabBar `calendar/settings` 탭 → 전용 풀스크린 화면. 탭바는 zIndex 120으로 유지.
- 그룹 pill / ExpandedHeader의 그룹 버튼 → GroupPickerOverlay open.
- FAB(+) → Composer (풀스크린, 자체 배경, zIndex 100, 탭바 가려짐 허용).

---

## Screens / Views

### 1. Map Home — default

**목적.** 홈. 가장 최근 기억의 장소들을 지도에 마커로 보이고, 바텀시트의 큐레이션이 "지금 볼 만한 기억들"을 제시.

**Top chrome (그룹 배너, `TopChrome`)**
- 위치: `top 54, left 16, right 16`, `background: THEME.sheet 94% + blur(24)`, 라운드 18, 섀도 `0 2px 8px rgba(64,56,51,0.06)`, border `0.5px #EBE1D4`.
- 좌측: 아바타 스택 (최대 3) — 커플 모드는 작은 하트 오버레이 1개 (Heart pin 심볼, 아바타 사이 중앙).
- 중앙: 그룹 이름 (Gowun Dodum 15/700/-0.2) + 서브라인.
  - 커플: `함께한 지 {N}일`
  - 일반 모임: `{멤버수}명 · 함께한 지 {N}일`
- 우측: 검색 아이콘 버튼 (32×32, surface).
- 전체 클릭 시 `onSwitchGroup()` → GroupPickerOverlay.

**Filter chip bar (`FilterChipBar`)**
- 위치: `top 108` (TopChrome 바로 아래에 밀착).
- 좌→우 가로 스크롤. 맨 왼쪽 `전체`(sparkle 아이콘) + 유저의 `categories` 리스트 + 마지막에 점선 + 버튼.
- 기본 카테고리: `추억(heart) · 밥(bowl) · 카페(cup) · 경험(compass)`.
- 활성 칩: `background primary, color #fff, shadow 0 2px 8px rgba(245,153,140,0.35)`.
- 비활성 칩: `background sheet, color textPrimary, border 0.5px divider`.
- + 버튼 → `CategoryEditorOverlay`.

**Map controls (`MapControls`)**
- 바텀 시트 `default` 상단에서 20pt 위, 오른쪽 16pt.
- 수직 스택 2개 버튼, 간격 8pt.
- 버튼 스타일: 40×40 circle, `background: sheet 94% + blur(24)`, 섀도 `0 2px 8px rgba(0,0,0,0.10)`.
  - 위: locationFill (현재 위치로 이동). 탭 시 살짝 scale(0.92) pulse.
  - 아래: northArrow (동서남북 재설정 — 지도 heading 0° 복원).

**FAB**
- 우하단, 탭바 위 18pt. 56×56 circle, primary grad, `+` 아이콘, 활성 태그 뱃지(있다면 Nunito 9/800).

**Bottom sheet (`BottomSheet`)**
- Snap 비율: `collapsed 0.08 / default 0.50 / expanded 1.0`.
- 핸들: 상단 중앙, 42×5 rounded 3, `rgba(64,56,51,0.2)`. `expanded`에서는 숨김 + 상단 `SheetExpandedHeader` 페이드인.
- 드래그: iOS 스프링 애니메이션 비슷하게 (`transition: transform 280ms cubic-bezier(0.32,0.72,0,1)`). `snap` 경계 넘으면 스냅핑.
- Collapsed 상태에서 핸들 아래에 `CollapsedSummary` — `우리의 추억 23 · 위로 스와이프` (커플) / `크루 기록 23 · 위로 스와이프` (모임). 폰트 Gowun Dodum 11.5.

**Sheet content (default state, `SheetCurated`)**
Sheet 상단 세그먼트 탭 — **큐레이션 / 보관함** (`SheetTabs`). 활성 탭의 배경은 sheet, 비활성은 투명. 섀도 `0 2px 6px rgba(64,56,51,0.08)`.

큐레이션 본문 (Photos-app 스타일 적응형 그룹):
- "이번 주": 가장 최근 이벤트 카드 (대형 사진 cover + 장소 pill + 추억 수).
- "이달의 추억": `EventStrip` — 가로 스크롤 이벤트 뱃지 (날짜 칩 + 제목 2줄 + 장소 칩).
- "장소 묶음": `PlaceBundleRow` — 같은 장소 3회 이상 방문 시 한 묶음, 3-up thumbnail.
- "Rewind 힌트": 월말이면 "이번 달 Rewind 보기" 카드 → `scene='rewind'`.

보관함 본문 (`SheetArchive`, Sprint 27):
- 상단 "모든 추억 · N개 이벤트 · M장" + 정렬 토글 `최신순/오래된순` (날짜 localeCompare).
- 이벤트 섹션 반복:
  - Header: 날짜 뱃지 (월 라벨 Nunito 8.5/800 uppercase + 일 Gowun Dodum 15/700), 타이틀 (14.5/700) + 장소/장수.
  - Gallery grid: `grid-template-columns: repeat(3,1fr); gap: 3px; border-radius: 14; overflow: hidden`.
  - 타일 aspect 1:1, 라운드 6, 위에 살짝 diagonal stripe overlay (사진 톤 통일 프리뷰).
  - 여러 장 있는 추억은 우상단 pill (rgba(0,0,0,0.35) + blur) 로 카운트 표시.

**Filtered state (`SheetFiltered`) — 마커 클릭 후**
- 컨텍스트 헤더: pin 배지 + 장소명 + "이 장소에서 N개의 추억" + X버튼.
- 이벤트 pill (날짜·요일).
- 추억 카드 리스트 (`MemoryRowCard`): 76×76 썸네일 + 시간 + 장소 + 2줄 노트 + 감정 태그 + 포스트/좋아요 카운트.
- 추억이 없으면 "이 장소의 첫 추억을 남겨보세요" placeholder 카드 + `+ 이 장소에 추억 추가` 대시 버튼.

### 2. Map Home — expanded state (Sprint 21)

전체가 마치 **새 페이지에 진입한 듯이** 바뀜:
- 핸들 숨김, TopChrome/FilterChipBar/MapControls/FAB 페이드아웃.
- 시트 상단에 `SheetExpandedHeader` 페이드인 (220ms). 구성: `← back / 그룹 pill (아바타+이름) / 검색 필드`. 배경은 sheet 투명 + 하단 0.5px divider.
- 본문은 큐레이션/보관함 그대로지만 스크롤 영역이 더 길어짐.
- Back 버튼 / 위→아래 드래그 시 `snap = 'default'`로 복귀 + 역순 페이드.

### 3. GroupPickerOverlay (신규)

풀 프레임 위에 뜨는 iOS-스타일 모달.
- Backdrop: `rgba(64,56,51,0.28) + blur(4)`, 탭 외부 시 close.
- Card: 폭 360, 라운드 24, 섀도 `0 20px 60px rgba(64,56,51,0.25)`, `max-height 80vh`.
- Header: "그룹 선택" + "여러 그룹을 동시에 쓸 수 있어요" 서브, 우측 close(X) 34px surface.
- Item: 카드 라운드 16.
  - 활성: `border 1.5px primary, background accentSoft`, 우측 체크 원 (primary 22px).
  - 비활성: `border 0.5px divider, background card`.
  - 좌측 아바타 스택 (최대 3, `-10` 겹침, 2px sheet 링) + 4명 이상이면 `+N` 버블.
  - 우측: 이름 + mode 배지 (`COUPLE` 코럴 `GROUP` 민트) + `N명 · 함께한 지 X일`.
- 맨 아래: `+ 새 그룹 만들기` 대시 버튼 (primary 66%).

**규칙:** 그룹은 여러 개를 **동시 소유**하며, 활성 그룹은 오직 1개. 활성 그룹의 `mode`가 지도/캘린더/Composer의 분기를 결정함. `activeGroupId` 변경 시 `scene='map-default'`로 리셋.

### 4. CategoryEditorOverlay (신규)

카테고리 **당 추억**(not 당 날짜) 단위 — 사용자가 자유롭게 추가/삭제.
- Header: "카테고리 편집" + 서브 "기본 · 추억 / 밥 / 카페 / 경험 · 직접 추가 가능".
- 기존 카테고리 리스트: 32×32 아이콘 배지 (accentSoft + primary 아이콘) + 이름 + X 삭제.
- 추가 블록: accentSoft 배경, `새 카테고리` label, 텍스트 입력 (placeholder `예: 산책, 공연, 전시…`) + "추가" 버튼. 아래 10개 아이콘 선택 (heart/bowl/cup/compass/mountain/sparkle/sun/camera/pin/yen).
- 푸터: `기본값` (reset, surface) + `저장` (primary CTA, flex 2:1).
- 저장 시 `localStorage.unf.cats` 업데이트. 가이드: 동일 이름 중복은 거절 (프로토타입과 동일).

### 5. Memory Detail

> Sprint 28 재구성 반영. 사용자 피드백 "이전/다음 동작 수정 + 설명 요소 재구성" 준수.

- 풀스크린, sheet 배경.
- 상단: back + 공유 + 북마크. 높이 54pt safe top.
- 캐러셀: 3:4 사진 히어로. 왼/오른 **스와이프 또는 ←→ 버튼은 같은 이벤트의 다른 추억 간에만 이동** (다른 이벤트로 넘어가지 않음).
- 메타 스트립: 날짜·시간 · 날씨 · 장소 pin · 작성자 아바타.
- 노트 (Gowun Dodum 15/500, 1.55 line-height, text-wrap: pretty).
- 태그 칩 (감정).
- **설명 요소 순서 (Sprint 28):**
  1) 이 장소 다시 가볼까? (유사 장소 카드 2개, 미니맵)
  2) 이벤트 안의 다른 추억들 (mini gallery)
  3) 같이 간 사람들 (아바타 + 이름, 일반 모임 모드)
  4) 지출 (있으면) / 날씨 상세
- 하단 고정 댓글 바 아님 — 본 제품은 private 이라 댓글 대신 **"한 줄 더 쓰기"** 인라인 입력 (같은 추억에 각 유저가 1개 글 최대).

### 6. Composer (새 추억)

**공통**
- 헤더: `취소 / 새 추억 / 저장`. 저장은 장소 confirmed 전에는 비활성 (chipBg + textTertiary).
- 사진 그리드 3열, 첫 장은 2×2. 빈 슬롯은 대시 + 아이콘.
- Source row: 앨범 / 카메라 / 파일 (SourceChip).
- "사진 메타데이터에서 가져온 정보" notice (accentSoft, sparkle 아이콘).

**필드 순서**
1. 장소 — `FieldRow`, 상태 `needs-confirm | confirmed`. needs-confirm일 때 `2px primary` 링 + "확인 필요" 배지. 아래 3-버튼 MiniButton: **이 장소 맞아요 (primary)** / **장소 변경** / **현재 위치로**. "장소 변경" → PickerSheet (검색 필드 + 후보 4개 + 현재 위치).
2. 시간 — 24-hour wheel picker (WheelPicker, 값 0~23 / 0~59). 모션 `snap`.
3. 이벤트 — "같은 날 이벤트에 묶임 · 새 이벤트 만들기".
4. **(general_group 전용) 이 추억의 참여자** — 그룹 멤버 아바타 칩 목록, 기본값 **전원 체크**. 해제 가능. `{N}/{총원}` 카운트 표시. 선택된 칩은 `background member.color+'22'` + `border 1.5px member.color` + 체크 아이콘.
5. 한 줄 기록 (textarea, card, min-height 80).
6. 감정 태그 — 설레임/따뜻함/행복/여유로움/즐거움/특별함/뭉클함 (복수 선택).
7. 지출 (선택) — ₩ 금액 입력 placeholder.

### 7. Calendar

**다이얼 네비** (Sprint 22): 월 이동은 상단의 수평 원형 다이얼(손가락으로 좌우 굴림) — 프로토타입에서는 좌우 화살표 + 월 라벨로 단순화. 구현 시 iOS는 `DatePicker(.wheel)` 또는 커스텀 `Circular dial`.
- 그리드: 7열, 요일 헤더 Nunito 10.5/700 textSecondary. 날짜 셀은 사이즈 44×44, 추억 있는 날에는 하단에 3점 도트 (primary).
- 날짜 선택 → 아래 Day Detail 패널.

**Day Detail**
- 날짜 타이틀 + 날씨.
- 이벤트 리스트 카드.
- **(general_group 전용) 계획 카드 (Sprint 29):** 민트 gradient 카드.
  - 타이틀: "다음 만남 — {요일/날짜}".
  - 장소 + 시작 시각.
  - RSVP 요약 (`✓ 3 · ? 1 · ✗ 0`).
  - 액션 row: `계획 추가` (primary CTA) + `알림 보내기` (secondary CTA, push-notify에 대응).
  - 알림 보내기 탭 시 바텀 토스트 "모든 멤버에게 알림을 보냈어요".

### 8. Rewind

월/연 단위 풀스크린 카드 스택 (Instagram Stories 느낌).
- Pager. 진행 바 상단 (분할 tick).
- 카드 종류: (a) 커버 제목 + 기간, (b) "가장 많이 간 곳 TOP 3" 리스트, (c) "처음 가본 곳" 갤러리, (d) "사진 가장 많이 찍은 날", (e) 감정 태그 클라우드, (f) 함께 보낸 시간.
- 카드 배경은 warm gradient (corals/sage/lavender 중 하나).
- 닫기 → sheet 'default'로 복귀.

### 9. Group Hub (설정)

- 그룹 이름 / 시작일 / 멤버 리스트 (모임 모드는 역할 라벨).
- **다른 그룹으로 전환** CTA → GroupPickerOverlay.
- 멤버 초대 (링크/QR) / 그룹 떠나기 / 그룹 삭제 (경고).
- 지도 테마 · 아이콘 팩(프리미엄) 섹션 (Sprint 7).
- 알림: 기념일·Rewind·멤버 활동.
- 데이터: iCloud 동기화 상태, 전체 내보내기 (JSON/사진 ZIP).

---

## Interactions & Motion

공통 easing: `cubic-bezier(0.32, 0.72, 0, 1)` — iOS 표준에 가까운 스프링성.

| 동작 | 대상 | 시간 | Easing |
| --- | --- | --- | --- |
| 시트 스냅 | transform translateY | 280ms | iOS 스프링 |
| 탭 스와이프 필터/정렬 | opacity + transform | 180ms | ease |
| 마커 선택 → 시트 확장 | opacity + translateY | 240ms | ease-out |
| ExpandedHeader 페이드 | opacity | 220ms | ease |
| FAB press | scale 0.96 | 120ms | ease |
| 모달 fade-in | backdrop opacity + card translateY(8→0) | 180ms | ease |
| 칩 선택 | background + shadow | 120ms | ease |
| 좋아요 하트 | scale 1→1.2→1 + 컬러 | 280ms | cubic-bezier(0.34,1.56,0.64,1) |

**핵심 제약 (Sprint 26):** 시트 내부 스크롤과 시트 드래그 핸들을 **분리**. 콘텐츠가 스크롤 top에 있을 때만 아래 드래그가 스냅 축소를 유발. 그 외엔 내부 스크롤.

**마커 클릭 (Sprint 23):** `scene='map-selected'; snap='default'`. 시트 첫 화면은 해당 이벤트의 클러스터 필터. 지도의 비선택 마커는 40% opacity로 희미하게.

---

## Data Model

프로토타입에서 실제 사용한 최소 모델 — 실제 앱의 DB 스키마 설계 시 참고하세요.

```ts
interface Group {
  id: string;
  name: string;
  mode: 'couple' | 'general_group';
  members: Member[];
  startedAt: string;       // YYYY.MM.DD
  anniversaryDays: number; // 파생, 표시용
}

interface Member {
  id: string;
  name: string;
  color: string;   // hex, 아바타 기본 색
  initial: string; // 한 글자
}

interface Event {       // 같은 날·같은 지역에 묶이는 논리 그룹
  id: string;
  groupId: string;
  title: string;
  date: string;       // YYYY.MM.DD (여행은 기간 '–' 허용: '2026.03.21–24')
  weekday: string;    // '목' 등
  place: string;
}

interface Memory {
  id: string;
  eventId: string;
  place: string;
  time: string;                // '14:20' 또는 '—'
  weather?: string;
  note: string;
  tags: string[];              // 감정 태그
  cover: string;               // gradient or image URL
  posts: number;               // 같은 이벤트에 묶인 다른 유저 포스트 수
  likes: number;
  participantIds?: string[];   // general_group만 의미 있음. 비어있으면 = 그룹 전원
  cost?: number;
}

interface Marker {
  id: string;
  x: number; y: number;        // 지도 좌표로 대체
  eventId: string;
  place: string;
  cluster?: boolean;
  count?: number;
}

interface Category {
  id: string;         // 표시 이름 (== 카테고리 key)
  icon: string;       // Icon 이름
}
```

---

## Tweaks (디자인 튜닝 파라미터)

Tweaks 패널에서 노출되는 값들은 **디자인 검토용**이지, 유저에게 그대로 노출하는 설정이 아닙니다. 구현 시에는 빌드-타임 환경 값/테마 토큰으로 고정하세요.

프로토타입에서 조정 가능했던 값:
- `mode: 'couple' | 'general_group'` — 활성 그룹 모드. 실제 앱에서는 `Group.mode` 로 결정.
- `mapTheme: 'default' | 'warm' | 'mono'` — Sprint 7 지도 테마.
- `sheetDefaultPct: 0.40~0.60` — 기본 스냅 비율 (권장 0.50).
- `primaryHue` / `secondaryHue` (옵션) — 커플 모드 기본 코럴 외 테마 팔레트 전환용.

> 시스템이 알려준 `Geumsan Heritage Serum.html` tweaks (iri-intensity 등)는 이 프로젝트의 것이 아니므로 무시하세요.

---

## Responsive / Platform Notes

- 1차 타깃은 iPhone. iPad 대응은 **scope 밖**.
- Dark mode: 프로토타입은 라이트만 정의. Sprint 8-B 톤을 그대로 어두운 변형으로 뒤집지 말 것 — 다크 팔레트를 따로 정의(후속 핸드오프 예정).
- 접근성: 최소 탭 타깃 44×44 pt. 본문 텍스트 색 대비 WCAG AA 이상 만족.
- 지도 성능(constraints.md): 마커 클러스터링, 화면에 보이는 범위만 렌더, 스크롤 fps 60 유지.

---

## Files in this bundle

```
design_handoff_unfading/
├── README.md                       ← 본 문서
└── prototype/
    └── Unfading Prototype.html     ← 단일 파일 React+Babel 프로토타입
```

프로토타입 HTML은 브라우저에서 바로 열람 가능하며, 네트워크 없이도 동작합니다. Tweaks 토글로 모드/스냅 기본값을 실험해보실 수 있습니다.

---

## Implementation checklist (Claude Code용)

구현 순서 제안 — 각 단계 끝에서 프로토타입의 해당 섹션과 픽셀 비교를 권장.

- [ ] 디자인 토큰 파일 (Color/Radius/Shadow/Typography) 생성, Gowun Dodum + Nunito 폰트 임베드
- [ ] 아이콘 시스템 — SF Symbols 매핑 표 + 커스텀 심볼 3개(bowl/cup/compass)
- [ ] Group/Member/Event/Memory/Marker/Category 모델 + 로컬 저장소 (UserDefaults 또는 CoreData/SwiftData)
- [ ] IOSFrame 루트 + safe-area 상수 처리
- [ ] BottomSheet (3-snap, presentationDetents / 커스텀 GestureState)
- [ ] TopChrome / FilterChipBar / MapControls / FAB
- [ ] SheetTabs + SheetCurated + SheetArchive
- [ ] Map layer + 마커 클릭 → SheetFiltered 플로우
- [ ] ExpandedHeader 페이드 전환 (snap=expanded 진입)
- [ ] GroupPickerOverlay (다중 그룹)
- [ ] CategoryEditorOverlay
- [ ] IOSTabBar 고정 + 캘린더/설정 풀스크린에서도 가시
- [ ] Composer (common) + general_group의 참여자 선택
- [ ] Calendar 다이얼 + 계획/알림(general_group)
- [ ] Memory Detail (Sprint 28 순서)
- [ ] Rewind 카드 스택
- [ ] Group Hub (설정 전체)
- [ ] 다크 모드 팔레트 정의 (후속 핸드오프)

---

## 마지막 주의사항

- 이 디자인의 본질은 **조용한 개인적 기록**입니다. SNS UI 언어(좋아요 눈에 띄게, 팔로우, 공개 피드 등)로 변형하지 말 것 — constraints.md의 "비공개 프라이빗" 원칙을 위배합니다.
- 커플 모드와 일반 모임 모드는 **카피/레이블이 다릅니다**. 예: "우리의 추억" vs "크루 기록", "함께한 지 N일" vs "{멤버수}명 · N일". 단일 문자열로 통일하지 말 것.
- 사진은 iOS 기본 앨범의 톤을 존중합니다. placeholder 그라데이션은 개발용으로만, 실제 UI는 사용자 사진이 주인공.
- "추억"은 **당 추억** 단위 카테고리, **당 날짜**가 아님. 검색/필터는 이 단위에 맞게 인덱싱하세요.
