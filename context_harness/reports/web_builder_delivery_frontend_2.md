---

## Implementation Report: 게스트 RSVP 플로우

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/types.ts` | `RsvpStatus`, `GuestRsvp`, `RSVP_STATUS_CONFIG`, `EventDetail` 타입 추가 |
| `src/lib/mock-event.ts` | 백엔드 대기 중 프론트엔드 개발용 목 이벤트 데이터 |
| `src/app/event/[id]/page.tsx` | SSR 이벤트 상세 페이지 + `generateMetadata`로 OG 카드 메타 (카카오톡 공유용) |
| `src/components/rsvp/event-hero.tsx` | 게스트용 이벤트 커버·호스트·일시·장소·참석자 수 표시 |
| `src/components/rsvp/rsvp-status-selector.tsx` | 참석/불참/미정 3상태 선택 UI (무드 컬러 연동) |
| `src/components/rsvp/rsvp-details-form.tsx` | 동행 인원 카운터 + 회비 납부 의사 선택 (참석 시에만 표시) |
| `src/components/rsvp/rsvp-confirmation.tsx` | 응답 완료 화면 + 응답 요약 + 참석자 아바타 프리뷰 + 응답 변경 |
| `src/components/rsvp/event-rsvp-flow.tsx` | 3단계 플로우 오케스트레이터 (view → respond → confirmed) |

### Flow Architecture

```
/event/[id] (SSR OG meta)
  └─ EventRsvpFlow (client, 3-phase state machine)
       ├─ view:      EventHero + "참석 여부 응답하기" CTA
       ├─ respond:   EventHero + RsvpStatusSelector + RsvpDetailsForm + "응답 제출하기"
       └─ confirmed: EventHero + RsvpConfirmation + "응답 변경하기"
```

### Remaining Dependencies (next subtask)

- **Backend lane**: `getMockEvent()` → Supabase `event` 테이블 쿼리로 교체 필요
- **Backend lane**: RSVP 제출 → Supabase `guest_states` 테이블 INSERT/UPSERT 필요
- **카카오 OAuth**: 응답 전 카카오 로그인 게이트 (Auth lane 완료 후 연동)
- **Realtime**: `guestCount` 실시간 갱신 (호스트 대시보드 subtask에서 구현)
