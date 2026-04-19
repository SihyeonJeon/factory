# Remediation — Sprints 12-14 Blockers

**Date:** 2026-04-14
**Source:** HIG Guardian Audit — Sprints 12-14
**Goal:** Fix 2 BLOCKER findings

---

## Fix B-1: Remove location permission request on launch

In `App/UnfadingApp.swift`:
- Remove `locationPermissionStore.handleCurrentLocationTap()` from the `.task` modifier
- The location permission should ONLY be requested when the user taps the location FAB button (which already calls `handleCurrentLocationTap()` in UnfadingHomeView)
- Keep the `@StateObject private var locationPermissionStore` and `.environmentObject(locationPermissionStore)` — the store should exist app-wide, just not trigger the permission dialog on launch

---

## Fix B-2: Add accessibility attributes to map annotations and clusters

In `Features/Home/MemoryClusterMapView.swift`:

After creating the hosting view for **memory annotations** (`configureMemoryView`), add:
```swift
annotationView.isAccessibilityElement = true
annotationView.accessibilityLabel = annotation.memory.place.title
annotationView.accessibilityValue = annotation.memory.emotions.first?.title
annotationView.accessibilityHint = "탭하면 추억 상세 정보를 봅니다."
annotationView.accessibilityTraits = .button
```

After creating the hosting view for **cluster annotations** (`configureClusterView`), add:
```swift
annotationView.isAccessibilityElement = true
annotationView.accessibilityLabel = "추억 클러스터"
annotationView.accessibilityValue = "\(cluster.memberAnnotations.count)개의 추억"
annotationView.accessibilityHint = "탭하면 이 지역 추억 목록을 봅니다."
annotationView.accessibilityTraits = .button
```

Note: `annotationView` is the `MKAnnotationView` returned/dequeued in these methods. Set the accessibility properties on the annotation view itself, not on the SwiftUI hosting controller's view.

---

## Files to modify

| File | Action |
|---|---|
| `App/UnfadingApp.swift` | MODIFY — remove location permission on launch |
| `Features/Home/MemoryClusterMapView.swift` | MODIFY — add accessibility to annotations |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
