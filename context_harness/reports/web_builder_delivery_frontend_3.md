---

## Implementation Report: 호스트 대시보드 Realtime UI

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/types.ts` | `GuestResponseStatus`, `DashboardGuest`, `AttendanceCounts` 타입 추가 |
| `src/lib/mock-dashboard.ts` | 8명 목 게스트 데이터 + `calcAttendanceCounts` 유틸리티 |
| `src/hooks/use-realtime-guests.ts` | Realtime 게스트 구독 훅 (목 데이터 + 시뮬레이션 콜백, Supabase Realtime 교체 가이드 포함) |
| `src/components/dashboard/attendance-summary.tsx` | 총 예상 인원 배너 + 참석/불참/미정/미응답 4칸 그리드 |
| `src/components/dashboard/guest-card.tsx` | 게스트 카드: 아바타 폴백, 이름, 동행, 상대 시간, 상태 Badge |
| `src/components/dashboard/guest-list.tsx` | 필터 탭(전체/참석/미정/불참/미응답) + 카드 리스트 |
| `src/components/dashboard/dashboard-view.tsx` | 대시보드 메인 컴포지션: 이벤트 헤더 + 참석 현황 + 게스트 목록 + Realtime 시뮬 버튼 |
| `src/app/dashboard/[id]/page.tsx` | SSR 대시보드 페이지 (OG metadata 포함) |

### Key Design Decisions

- **모바일 퍼스트**: `max-w-2xl` 컨테이너, 터치 친화적 필터 탭, 44px+ 터치 타겟
- **무드 테마 연동**: 이벤트 무드 컬러가 배너·필터·로딩 스피너에 일관 적용
- **Realtime 준비**: `useRealtimeGuests` 훅에 Supabase `postgres_changes` 구독 교체 가이드 주석 포함. `simulateNewRsvp`로 미응답→참석 전환 데모 가능
- **아바타 폴백**: 이름 첫 글자 + 안정적 hue 생성으로 프로필 사진 없이도 시각적 구분

### Remaining Dependencies for Next Subtask

- **Backend lane**: `guest_states` 테이블 Supabase Realtime publication이 완료되면 `useRealtimeGuests` 훅 내부를 실제 구독으로 교체
- **Auth**: 카카오 OAuth 연동 후 호스트 권한 체크 추가 필요 (현재는 인증 없이 접근 가능)
