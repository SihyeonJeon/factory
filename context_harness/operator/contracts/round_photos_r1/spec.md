# round_photos_r1 Spec

## Scope

Round 20 wires memory composer photo selection to Supabase Storage bucket `memories`.

## Requirements

- Upload selected memory photos before inserting the memory row.
- Store uploaded object paths in `memories.photo_urls` and the first path in `memories.photo_url`.
- Use object paths shaped as `<group_id>/<memory_id>/<filename>.jpg`.
- Generate the memory UUID before upload so Storage paths and the inserted memory row share the same memory id.
- Resolve private bucket images through short-lived signed URLs before rendering.
- Keep Korean composer UI and preserve existing 44pt interactive target conventions.

## Storage Contract

- Bucket: `memories`
- Public access: disabled
- Max upload size: 25MB
- Upload content type: `image/jpeg`
- RLS compatibility: object path group and memory UUID segments are lowercase UUID strings to match Postgres `uuid::text` path-prefix policies.

## Implementation Notes

- `PhotoUploader` owns PHAsset loading, JPEG resizing/encoding, Storage upload, signed URL creation, and best-effort cleanup.
- `MemoryComposerState` owns save orchestration, upload progress, memory-id generation, and rollback cleanup when DB insertion fails.
- `RemoteImageView` renders Storage paths via signed URLs and falls back to the existing themed placeholder.

## Out Of Scope

- Database schema migrations; `photo_url` and `photo_urls` already exist.
- Offline upload queueing or retry persistence.
- Replacing sample map/detail data with live memory queries.
