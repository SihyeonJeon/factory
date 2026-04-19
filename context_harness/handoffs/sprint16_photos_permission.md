# Sprint 16 — Photos Permission Guard + Sample Data Cleanup

**Date:** 2026-04-14
**Source:** Screenshot review — Photos 전체 접근 다이얼로그 앱 시작 시 표시
**Goal:** Photos 권한 없이도 앱이 정상 로드되도록 수정

---

## Root Cause

1. `SampleModels.swift` — 더미 메모리에 가짜 photo identifier ("sample-hongdae-1" 등) 포함
2. `PhotoLoader.loadImage()` — `PHAsset.fetchAssets()` 호출 시 Photos 권한 다이얼로그 트리거
3. `AsyncPhotoView` — `.task`에서 즉시 `PhotoLoader.shared.loadImage()` 호출
4. `MemoryPinMarker`/`MemoryClusterMapView` — 마커 렌더링 시 photo identifier가 있으면 AsyncPhotoView 사용

---

## Fix 1: PhotoLoader에 권한 확인 추가

In `Shared/PhotoLoader.swift`:

```swift
import Photos

@MainActor
final class PhotoLoader: ObservableObject {
    static let shared = PhotoLoader()
    
    private var cache: [String: UIImage] = [:]
    
    func loadImage(
        identifier: String,
        targetSize: CGSize = CGSize(width: 200, height: 200)
    ) async -> UIImage? {
        if let cached = cache[identifier] { return cached }
        
        // Guard: only attempt PHAsset fetch if photo library access is authorized
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            return nil  // Return nil placeholder, don't trigger permission dialog
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = result.firstObject else { return nil }
        
        // ... rest unchanged
    }
}
```

## Fix 2: Sample data — photo identifiers를 빈 배열로

In `Shared/SampleModels.swift`:
- 모든 `photos:` 배열을 빈 배열 `[]`로 변경
- 시뮬레이터에 실제 사진이 없으므로 가짜 identifier는 불필요
- Photos 권한 다이얼로그 트리거 방지

---

## Files to modify

| File | Action |
|---|---|
| `Shared/PhotoLoader.swift` | MODIFY — PHPhotoLibrary 권한 확인 추가 |
| `Shared/SampleModels.swift` | MODIFY — photo identifiers를 빈 배열로 변경 |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- 앱 시작 시 Photos 권한 다이얼로그 표시 금지.
- PhotosPicker 사용 시에만 권한 요청 가능.
