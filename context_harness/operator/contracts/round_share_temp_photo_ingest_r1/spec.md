# round_share_temp_photo_ingest_r1 — Shared temp-file photos must appear in the composer

## Purpose
- Share Extension은 PHAsset identifier가 없을 때 temp file path를 deep link로 넘기지만 composer는 assetIdentifier만 사용해 사진을 무시한다. 목표는 temp file fallback도 composer 사진 입력으로 표시/업로드되는 것이다.

## Plan
- 수정 파일: `workspace/ios/Features/Home/MemoryComposerSheet.swift` lines 26-40, 594-599; `workspace/ios/Features/Home/MemoryComposerState.swift` lines 56-76; `workspace/ios/App/ComposerLaunchRoute.swift` lines 3-16; 필요 시 `workspace/ios/ShareExtension/ShareViewController.swift` lines 103-144.
- 예상 변경 line 수: 45-80.
- 의존성: 없음.

## Acceptance (≤3)
1. `ComposerLaunchPhotoReference.tempFilePath`가 composer state로 전달되어 photo section에 공유 이미지로 나타난다.
2. asset identifier 경로는 기존 PhotosPickerItem 흐름을 유지한다.
3. 단위 테스트 또는 UI smoke가 `unfading://composer?photo=/tmp/...jpg` deep link에서 사진 입력이 비어 있지 않음을 검증한다.

## Verification (3축)
- 코드: `MemoryComposerSheet.swift:37`의 `sharedPhotoReference?.assetIdentifier` 단일 경로가 temp file path도 처리하는 구조로 바뀌었는지 확인.
- 실사용 (simulator UITest 또는 실기기 smoke 권장 항목): Files/Photos share extension fallback 또는 deep link로 temp path 주입 후 composer photo preview 표시 확인.
- 프로세스: `evidence/notes.md`에 assetIdentifier case와 tempFilePath case를 분리 기록.

## Record
- `evidence/notes.md` 기록 항목: deep link URL, reference enum case, composer state field, preview/upload 검증 결과.
