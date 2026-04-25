# Acceptance — round_share_temp_photo_ingest_r1

## A1. tempFilePath → composer photo
`ComposerLaunchPhotoReference.tempFilePath(let path)` 가 composer state 로 전달.
사진 섹션에 file URL 의 image 가 preview/썸네일 로 노출됨.

## A2. assetIdentifier 경로 보존
기존 `assetIdentifier` (PhotosPickerItem) 경로는 변경 없이 동작.

## A3. 검증 테스트
단위 또는 UI 테스트가 `unfading://composer?photo=/tmp/foo.jpg` deep link 시
composer 사진 입력이 비어있지 않음 assert.
