# 2. PRD (Product Requirements Document) - Unfading

> [!NOTE]
> 본 PRD는 자율 플러그인 에이전트(Codex, Claude Code 등)가 최소한의 할루시네이션(Hallucination)으로 React 제가티브(Expo) 앱을 구축할 수 있도록 설계된 **AI 친화적(AI-Friendly) 스캐폴딩 마스터버전**입니다.

## 📱 1. Product Concept (Unfading)
- **대상 장르:** 프라이빗 공간 소셜 다이어리 (Private Spatial Journaling) / LBS 기반 라이프로깅.
- **핵심 목표:** 파편화된 사진과 추억들을 지도 위에 엮어내어(Clustering), 특정 모임(Group)끼리 위치 기반의 서사(Timeline)를 그릴 수 있는 동적 캘린더-갤러리 생태계 구축.

## 🛠️ 2. 기술 스택 (The Triad SOTA Setup - 2026.04)
에이전트가 `npx expo install` 등을 통해 구축해야 하거나 기설치된 하네스(Harness) 도구들입니다.
- **Framework:** `Expo (SDK 50+)`, `Expo Router` (파일 시스템 기반 네비게이션)
- **Map Renderer:** `react-native-maps`, `react-native-map-clustering` (네이티브 맵 + 클러스터)
- **Interactive UI Thread:** `@gorhom/bottom-sheet`, `react-native-reanimated`, `react-native-gesture-handler` (60fps 보장)
- **Global State:** `zustand`
- **Styling:** `nativewind` (Design Tokens 기반)
- **Backend/DB:** `supabase-js`

---

## 🏗️ 3. 기능 및 레이아웃 스캐폴딩 로직 (Epic & Tasks)

### Epic 1: Map-Slider Synchronization (핵심 UI/UX)
마커(위치)와 바텀시트(갤러리 데이터) 간의 유체적 동기화 구현.
- **Layer 0 (Map):** `absoluteFillObject`로 맵 렌더링. 줌 인/줌 아웃 시 클러스터 마커 자동 분해 및 합체.
- **Layer 1 (BottomSheet):** 맵 위에 플로팅되는 하단 패널(`display: flex`).
- **Interaction Rule:**
  1. 마커 클릭 비선택 시 BottomSheet는 최하단(화면 높이 15%)으로 Snap.
  2. 마커 터치 시 BottomSheet는 자동으로 55% 높이로 튀어오르며(`withSpring` 애니메이션), 내부는 선택된 마커의 장소/시간 단위 사진 포스트들의 Masonry Grid로 전환됨.
  3. 시트 스크롤과 제스처 상충 방지를 위해 `@gorhom/bottom-sheet` 내부의 ScrollView를 활용.

### Epic 2: Collaborative Memory Tree (데이터 구조)
데이터는 Supabase 기반 3단계 계층을 따름. TypeScript 인터페이스(`types.ts`)로 이 구조를 최상단에 강제 선언할 것.
1. `Group`: 모임 (커플, 친구) 객체 (멤버 리스트 포함)
2. `Memory`: 마커 생명의 중심이 되는 이벤트 단위 (장소 좌표 Point, 대표 날짜, 썸네일 경로 보유)
3. `MemoryPost`: `Memory` 하위에 분기되는 멤버 각자의 코멘트, 다중 사진 데이터 레코드.

### Epic 3: Strict UI Guidelines (디자인 헌법)
- **Apple HIG 필수 준수:**
  - 모든 클릭/터치 가능 요소(`TouchableOpacity`, `Pressable`)는 반드시 `min-w-[44px] min-h-[44px]` (Tailwind 표기법) 이상을 확보할 것.
  - 디스플레이 노치/홈 인디케이터 침범을 막기 위해 맵을 제외한 모든 입력창은 `SafeAreaView` 구역 내에 한정.
- **Styling:** 흑백 원색을 지양하고 iOS 환경에 어울리는 파스텔톤(예: `bg-slate-50`, `text-indigo-900`)과 투명도(`backdrop-blur`)를 가진 Glassmorphism 적극 사용.

---

> [!WARNING]  
> ## 🚨 4. Deploy Safeties (빌드/배포 안전 수칙)
> 에이전트 박스 내에서 자율(YOLO) CLI가 작동 중 결함(인터랙티브 대기)에 빠지지 않기 위한 DevOps 수칙.
> 1. **EAS Build Bypass Rule:** `eas build` 커맨드 실행 시 터미널에서 Apple Developer Login 프롬프트를 요구하며 무한 대기할 수 있음. 
> 2. **Mock Compilation:** 환경변수(`EXPO_APPLE_DEV_TEAM`)가 주입되지 않은 상황의 테스트 루프라면, 실제 클라우드 EAS 대신 `npx expo export` 또는 웹(`start --web`) Mock 빌드를 통해 Syntax 및 번들러 통과 검증까지만 수행할 것. (절대 인터랙티브 인증에서 정지시키지 말 것)