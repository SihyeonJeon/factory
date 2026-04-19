# Remediation — Location Permission Triggered by Map

**Date:** 2026-04-14
**Source:** Visual QA — location dialog still appears on launch after B-1 fix
**Root Cause:** `MemoryClusterMapView.swift:24` sets `mapView.showsUserLocation = true` unconditionally. MKMapView automatically requests location permission when this is set.

---

## Fix

In `Features/Home/MemoryClusterMapView.swift`:

1. Add a property to receive the current location permission state:
```swift
var locationAuthorized: Bool = false
```

2. In `makeUIView`, change line 24:
```swift
// OLD: mapView.showsUserLocation = true
// NEW:
mapView.showsUserLocation = locationAuthorized
```

3. In `updateUIView`, update the property when authorization changes:
```swift
mapView.showsUserLocation = locationAuthorized
```

In `Features/Home/UnfadingHomeView.swift`:
- Where `MemoryClusterMapView` is instantiated, pass the location permission state:
```swift
MemoryClusterMapView(
    ...,
    locationAuthorized: locationPermissionStore.permissionState == .authorized
)
```

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/MemoryClusterMapView.swift` | MODIFY — conditional showsUserLocation |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — pass locationAuthorized param |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- After fix, cold launch must NOT show location permission dialog.
