Build passes, TypeScript compiles cleanly. Here's the implementation report:

---

## Implementation Report: Supabase Storage 정책 + media_timeline 업로드 파이프라인

### Changed / Created Files

| File | Purpose |
|------|---------|
| `supabase/migrations/00005_storage_policies.sql` | Creates `event-media` Storage bucket (private, 10MB limit, image MIME types only) + 3 RLS policies: participant read, participant upload (enforces `{event_id}/{user_id}/` path ownership), uploader-only delete |
| `src/lib/storage.ts` | Client-side helper library — `uploadEventPhoto()` (upload + insert media_timeline), `getSignedMediaUrls()` (batch signed URL generation), `deleteEventPhoto()` (cleanup both Storage + DB) |
| `src/lib/queries/media.ts` | Server-side query — `getEventPhotos()` fetches media_timeline rows joined with profiles, batch-signs all storage paths, returns `TimelinePhoto[]` |
| `src/app/api/media/upload/route.ts` | `POST /api/media/upload` API route — validates auth, file type/size, 10-photo-per-event limit, uploads to Storage, inserts media_timeline record, returns signed URLs + uploader profile |
| `src/components/photos/photo-upload-button.tsx` | Replaced mock `URL.createObjectURL` upload with real `fetch("/api/media/upload")` FormData upload pipeline |
| `src/app/event/[id]/photos/page.tsx` | Replaced `getMockPhotos()` + `getMockEvent()` with real Supabase queries (`getEventPhotos` + events table join), mock fallback retained for event detail when DB row is absent |

### Storage Architecture

- **Bucket**: `event-media` (private)
- **Path pattern**: `{event_id}/{uploader_id}/{uuid}.{ext}`
- **Access**: Signed URLs (24h for reads, 7d on upload response)
- **RLS enforcement**: Both Storage policies and media_timeline table RLS require event participation (host or RSVP'd guest)

### Remaining Dependencies for Next Subtask

- `settlement-calc Edge Function` — next backend lane task. No dependency on this subtask.
- `mock-photos.ts` can be removed once frontend lane confirms no other pages reference it.
