Build passes. All routes are registered including `/event/[id]/photos`.

---

## Implementation Report: 사진 타임라인 + 스와이프 뷰어

### Changed / Created Files

| File | Purpose |
|------|---------|
| `src/lib/types.ts` | `TimelinePhoto` 인터페이스 추가 (id, url, thumbnailUrl, uploader, dimensions) |
| `src/lib/mock-photos.ts` | 8장 목 사진 데이터 (picsum.photos 플레이스홀더), `getMockPhotos()` |
| `src/components/photos/photo-timeline.tsx` | 시간대별 그룹화 (오전/오후/저녁) + 3컬럼 그리드 + lazy loading 썸네일 |
| `src/components/photos/photo-swipe-viewer.tsx` | 풀스크린 뷰어: 터치 스와이프 (SWIPE_THRESHOLD 50px, 엣지 댐핑), 키보드 좌우/ESC, 데스크톱 화살표 버튼, 닷 인디케이터, 업로더 프로필 표시 |
| `src/components/photos/photo-upload-button.tsx` | 파일 선택 → 로컬 프리뷰 (mock upload), 10MB/JPEG+PNG+WebP+HEIC 검증, 잔여 장수 표시 |
| `src/components/photos/photos-page-view.tsx` | 페이지 컨테이너: 이벤트 헤더 + 업로드 버튼 + 타임라인 + 뷰어 오버레이 조합 |
| `src/app/event/[id]/photos/page.tsx` | SSR 라우트 (OG 메타 + 목 데이터 주입) |
| `src/components/rsvp/event-rsvp-flow.tsx` | 이벤트 페이지에 "사진 타임라인" 링크 카드 추가 |
| `src/components/dashboard/dashboard-view.tsx` | 호스트 대시보드에 "사진 타임라인" 링크 카드 추가 |

### Key Design Decisions

- **터치 스와이프**: 수평/수직 방향 감지 후 수평만 처리, 양끝에서 0.3x 댐핑으로 자연스러운 바운스 피드백
- **시간대 그룹화**: 업로드 시간 기준 오전/오후/저녁 분리 → 타임라인 스토리텔링
- **이벤트당 10장 제한**: `MAX_PHOTOS_PER_EVENT` 상수, 업로드 버튼에서 잔여 장수 표시
- **Body scroll lock**: 뷰어 오픈 시 `overflow: hidden` 설정/복원

### Remaining Dependencies for Next Subtask

- **Supabase Storage 연동**: `photo-upload-button.tsx`의 mock `URL.createObjectURL`을 Supabase Storage 업로드로 교체 필요 (backend lane)
- **media_timeline 테이블**: `getMockPhotos()`를 Supabase 쿼리로 교체 (backend lane)
- **사용자 인증**: 업로드 시 `uploaderName`을 현재 로그인 사용자 프로필에서 가져오도록 변경 필요
