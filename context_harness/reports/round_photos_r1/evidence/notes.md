# round_photos_r1 Evidence Notes

## Implementation Notes

- Added private-bucket upload support through `PhotoUploader`.
- Added signed URL rendering through `RemoteImageView`.
- Composer save now creates the memory id before upload and writes Storage paths to `photo_url` / `photo_urls`.
- Upload progress is exposed as `uploadProgress` and rendered in Korean as `사진 업로드 중... N%`.
- Uploaded files are deleted best-effort if memory row creation fails.

## Schema / RLS Notes

- Existing Storage RLS expects object names under `<group_id>/...`.
- Storage path UUID segments are lowercased to match Postgres `uuid::text` output.

## Verification

- Passed: `cd workspace/ios && xcodegen generate`.
- Blocked: requested `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,id=00FCC049-D60A-4426-8EE3-EA743B48CCF9' -derivedDataPath .deriveddata/r20 -resultBundlePath .deriveddata/r20/Test-R20.xcresult`.
- Blocker detail: SPM dependency fetch could not resolve `github.com` for Supabase and transitive packages (`Could not resolve host: github.com`).
- Environment detail: CoreSimulatorService was unavailable in the sandbox before package resolution completed.
