# Constraints

## Platform

- Primary target: 웹 (Next.js SSR + PWA)
- 호스트: Next.js 웹 앱 (데스크톱 + 모바일 반응형)
- 게스트: PWA 기반 모바일 웹 (앱 설치 불필요)
- 호스트 모바일 앱 (React Native): Phase 2 이후 검토

## Tech stack

- Frontend: Next.js 15+ (App Router, SSR for OG meta)
- Styling: Tailwind CSS + shadcn/ui
- Backend: Supabase (Auth, PostgreSQL, Realtime, Edge Functions, Storage)
- Auth: 카카오 로그인 (Supabase OAuth) + Apple 로그인 (대체)
- Push: Firebase Cloud Messaging (MVP), 카카오 알림톡 (Phase 2)
- 정산: 토스/카카오페이 딥링크 (PG 라이선스 불필요)
- Image: Supabase Storage + Next.js OG Image generation
- Hosting: Vercel
- Language: TypeScript (strict mode)

## Must-have MVP features (8주)

1. 이벤트 페이지 생성 + 카카오톡 OG 공유
2. PWA 기반 모바일 웹 RSVP (앱 설치 불필요, 카카오 로그인 원탭)
3. 참석 상태 대시보드 + D-1 리마인더
4. 사진 업로드 + 타임라인
5. 토스/카카오페이 딥링크 정산

## Product constraints

- 게스트 RSVP는 앱 설치 불필요가 절대 조건 (PWA/모바일 웹)
- 카카오톡 공유 시 OG 미리보기가 예쁘게 렌더링되어야 함 (SSR 필수)
- 호스트 1명이 8~15명 게스트를 초대하는 구조적 바이럴을 전제로 설계
- 관계 인텔리전스 레이어는 MVP에서 데이터 수집만, Phase 2에서 활성화
- 한국어 UI/UX 우선, 영어는 Phase 2

## Data model

- `event`: 모임 메타데이터, 장소, 시간, 무드, 호스트 ID
- `guest_state`: 참석/불참/대기, 동행, 회비 상태
- `attendance_graph`: 공동 참석 관계 (사용자 A ↔ B, 횟수, 마지막 만남) — Phase 2 활성화
- `media_timeline`: 모임별 사진·미디어
- `relationship_score`: 관계 강도 (빈도 + 최근성) — Phase 2 활성화
- `profile`: 사용자 프로필 (카카오 연동)

## UX constraints

- 이벤트 페이지 생성은 60초 이내 완료 가능해야 함
- 게스트 RSVP는 1탭 응답이 목표 (로그인 후 즉시 참석/불참/대기 선택)
- 모바일 퍼스트 디자인 (게스트 대부분 모바일에서 접근)
- 감성적이고 따뜻한 톤 (Partiful 수준의 이벤트 페이지 미학)
- 한국 2030세대 취향에 맞는 커버 이미지·컬러 템플릿

## Technical constraints

- Supabase Row Level Security (RLS) 필수 적용
- 모든 Edge Function은 타입 안전성 확보 (TypeScript strict)
- Supabase Realtime으로 참석 상태 실시간 반영
- OG 이미지는 동적 생성 (Next.js OG Image API 또는 Vercel OG)
- 이미지 업로드 최대 10장/이벤트, 최대 5MB/장
- PWA manifest + service worker 필수 (오프라인 기본 페이지)

## Security & privacy

- 소셜 그래프 데이터(누구와 얼마나 자주 만나는가)는 민감 데이터로 분류
- 개인정보보호법 및 정보통신망법 준수
- 게스트 RSVP 시 관계 데이터 수집 동의 절차 필수
- 관계 그래프 데이터 제3자 제공 금지
- 사용자 삭제 요청 시 완전 삭제 가능 구조

## Token and orchestration constraints

- No single provider may both implement and self-approve release-critical work.
- Use compressed handoff artifacts instead of replaying full history.
- Compression targets:
  - Product handoff: <= 800 words
  - Delivery plan: <= 700 words
  - Builder brief: <= 400 words
  - Review summary: <= 500 words
- Engineering should only re-enter after evaluation produces concrete, localized feedback.

## Revenue constraints

- 프리미엄 + 구독 모델
- 무료 tier: 가치 검증 가능하되 명확히 제한 (월 3회)
- 과금 패턴은 사기적이거나 리뷰 리스크 있는 행위 금지
