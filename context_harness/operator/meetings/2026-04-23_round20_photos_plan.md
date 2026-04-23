---
round: round_photos_r1
stage: coding_1st
status: draft
participants: [codex]
decision_id: 20260423-r20-photos
contract_hash: none
---

## Context

- Supabase Storage bucket `memories` is private and guarded by path-prefix RLS.
- The composer already supports photo picking with `PhotosPickerItem`.
- `DBMemory` and `DBMemoryInsert` already expose `photo_url` and `photo_urls`.
- Storage paths must reference the new memory id before DB insert.

## Proposal

- Add `PhotoUploader` for PHAsset-to-JPEG upload, signed URL creation, and cleanup.
- Generate a memory id in `MemoryComposerState.save`, upload selected PHAssets, then insert `DBMemoryInsert` with the same id.
- Add `RemoteImageView` and wire storage-path rendering into photo grid/detail surfaces.
- Surface Korean upload progress in the composer and disable save while uploading.

## Questions

- Exact supabase-swift Storage method signatures must be verified by `xcodebuild` against package version 2.30.0.

## Counter / Review

- RLS path comparison uses `group_id::text`; Swift `UUID.uuidString` is uppercase by default. Storage object paths should lowercase UUID segments to avoid text equality failures.
- `PhotosPickerItem` does not directly upload; save orchestration must resolve item identifiers to `PHAsset` and treat unresolved assets as no-upload rather than blocking text-only memory creation.

## Convergence

- Proceed with lowercase `<group_id>/<memory_id>/<filename>.jpg` object paths.
- Preserve existing picker UI and add PHAsset resolution only in save state.

## Decision

- Implement Round 20 photo upload with lowercased UUID storage paths, signed URL rendering, upload progress, and best-effort Storage cleanup on DB insert failure.

## Challenge Section

- Challenge: If selected PhotosPicker items cannot resolve to `PHAsset`, the first implementation may silently save without photos. This is acceptable for this coding round only if tests and evidence call out the limitation; a later pass should add a user-facing asset resolution error if this happens in real devices.
