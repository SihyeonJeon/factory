# Eval Protocol — round_share_temp_photo_ingest_r1

## Author / Verifier
- Author: implementer Codex (fresh session, dispatch-1).
- Verifier: 별도 fresh Codex (dispatch-2). Author ≠ Verifier.

## 3-axis verification

### Code axis
- `rg 'sharedPhotoReference?.assetIdentifier' workspace/ios/Features/Home/MemoryComposerSheet.swift`
  → tempFilePath 도 처리하도록 변경 확인.
- `ComposerLaunchPhotoReference.tempFilePath` 가 view chain 까지 도달.

### Runtime axis
- xcodebuild test : 새 단위 테스트 PASS + 기존 테스트 회귀 0.
- (선택) simulator deep link 호출 시뮬: `xcrun simctl openurl <UDID> "unfading://composer?photo=/tmp/test.jpg"` → composer photo preview placeholder 또는 실제 이미지 노출.

### Process axis
- Acceptance ≤3, lock 파일 존재, evidence/notes.md 가 §D 템플릿 형식, 두 case (assetId vs tempFilePath) 명시 분리.
