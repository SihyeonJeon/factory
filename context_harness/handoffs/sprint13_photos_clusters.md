# Sprint 13 — Photo Display + Cluster Photo Markers

**Date:** 2026-04-14
**Source:** Human Feedback Round 2 — HF2-4, HF2-5
**Goal:** Fix photo display in app, show photos in cluster markers

---

## Task 1: Fix Photo Display (HF2-4)

### Problem
사진을 업로드해도 앱에서 볼 수 없음.

### Root Cause
`DomainMemory.photoLocalIdentifiers` stores PHAsset local identifiers. The app needs to use Photos framework to load actual images from these identifiers.

### Implementation

Create `Shared/PhotoLoader.swift`:

```swift
import Photos
import SwiftUI

@MainActor
final class PhotoLoader: ObservableObject {
    static let shared = PhotoLoader()
    
    private var cache: [String: UIImage] = [:]
    
    func loadImage(identifier: String, targetSize: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        if let cached = cache[identifier] { return cached }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = result.firstObject else { return nil }
        
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image {
                    self.cache[identifier] = image
                }
                continuation.resume(returning: image)
            }
        }
    }
}
```

Create `Shared/AsyncPhotoView.swift` — reusable view component:

```swift
struct AsyncPhotoView: View {
    let identifier: String
    let targetSize: CGSize
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(UnfadingTheme.surfaceOverlay)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(UnfadingTheme.textSecondary)
                    }
            }
        }
        .task {
            image = await PhotoLoader.shared.loadImage(identifier: identifier, targetSize: targetSize)
        }
    }
}
```

### Apply to views:

1. **MemoryGalleryView.swift** — photo grid tiles: use `AsyncPhotoView` instead of placeholder
2. **MemoryDetailView.swift** — full photos: use `AsyncPhotoView` with larger targetSize
3. **MemoryBriefView.swift** — hero photo: use `AsyncPhotoView`
4. **MemoryComposerSheet.swift** — photo preview after selection: use `AsyncPhotoView`

---

## Task 2: Cluster Markers with Photos (HF2-5)

### Problem
현재 클러스터 마커가 이모지 아이콘으로 표시됨.

### Implementation

Modify `Features/Home/MemoryPinMarker.swift` or create cluster annotation view:

For **single markers**: if memory has photos, show a circular photo thumbnail instead of emoji icon
For **cluster markers**: show the first memory's photo as a circular thumbnail with a count badge

```swift
// Single marker with photo
struct MemoryPhotoMarker: View {
    let memory: DomainMemory
    
    var body: some View {
        ZStack {
            if let firstPhoto = memory.photoLocalIdentifiers.first {
                AsyncPhotoView(identifier: firstPhoto, targetSize: CGSize(width: 80, height: 80))
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(UnfadingTheme.primary, lineWidth: 2))
                    .shadow(color: UnfadingTheme.primary.opacity(0.2), radius: 4, y: 2)
            } else {
                // Fall back to existing emoji/icon marker
                existingMarkerContent
            }
        }
    }
}

// Cluster marker with photo + count
struct ClusterPhotoMarker: View {
    let memories: [DomainMemory]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let firstPhoto = memories.first?.photoLocalIdentifiers.first {
                AsyncPhotoView(identifier: firstPhoto, targetSize: CGSize(width: 80, height: 80))
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(UnfadingTheme.primary, lineWidth: 2))
            }
            
            // Count badge
            Text("\(memories.count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(UnfadingTheme.primary, in: Capsule())
                .offset(x: 4, y: -4)
        }
    }
}
```

### Integration:
- In `UnfadingHomeView.swift` map annotations: use `MemoryPhotoMarker` for single annotations
- For cluster annotations: use `ClusterPhotoMarker`
- Keep fallback to emoji/icon marker when no photos exist

---

## Files to create/modify

| File | Action |
|---|---|
| `Shared/PhotoLoader.swift` | **NEW** — PHAsset image loading |
| `Shared/AsyncPhotoView.swift` | **NEW** — reusable photo view |
| `Features/Home/MemoryPinMarker.swift` | MODIFY — photo variant |
| `Features/Home/MemoryGalleryView.swift` | MODIFY — use AsyncPhotoView |
| `Features/Home/MemoryDetailView.swift` | MODIFY — use AsyncPhotoView |
| `Features/Home/MemoryBriefView.swift` | MODIFY — use AsyncPhotoView |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — cluster photo markers |
| `Features/Home/MemoryClusterMapView.swift` | MODIFY — photo-based cluster annotations |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- Photo loading must be async, non-blocking.
- Graceful fallback when photo access is denied or identifier is invalid.
- All new UI text in Korean.
- Use UnfadingTheme.
