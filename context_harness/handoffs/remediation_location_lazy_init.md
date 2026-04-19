# Remediation — Lazy CLLocationManager Initialization

**Date:** 2026-04-14
**Source:** Visual QA — location dialog STILL appears on cold launch
**Root Cause:** On iOS 26, `CLLocationManager()` creation with `NSLocationWhenInUseUsageDescription` in Info.plist triggers the permission dialog automatically.

---

## Fix

In `Shared/LocationPermissionStore.swift`:

Change the convenience init to use lazy initialization — do NOT create `CLLocationManager()` until the user actually taps the location button.

```swift
convenience init() {
    // Do NOT create CLLocationManager here — it triggers the permission dialog on iOS 26
    // Use a lazy wrapper that only creates the manager on first access
    var _manager: CLLocationManager?
    
    func getManager() -> CLLocationManager {
        if let m = _manager { return m }
        let m = CLLocationManager()
        _manager = m
        return m
    }
    
    self.init(
        currentStatus: {
            if let m = _manager {
                return m.authorizationStatus
            }
            // Before first interaction, report notDetermined
            return .notDetermined
        },
        requestWhenInUseAuthorization: {
            getManager().requestWhenInUseAuthorization()
        },
        retainedLocationManager: nil  // will be set lazily
    )
}
```

Also update `currentCoordinate` to handle the nil manager:
```swift
var currentCoordinate: CLLocationCoordinate2D? {
    guard permissionState == .authorized else {
        return nil
    }
    return retainedLocationManager?.location?.coordinate
}
```

This is already correct since `retainedLocationManager` is optional.

### Alternative simpler approach:

If the above is too complex, simply remove the `CLLocationManager()` creation from the convenience init and create a factory method:

In `LocationPermissionStore`:
```swift
convenience init() {
    // Start with no manager — notDetermined state
    self.init(
        currentStatus: { .notDetermined },
        requestWhenInUseAuthorization: { },
        retainedLocationManager: nil
    )
}

func activateLocationManager() {
    // Called only when user taps location button for the first time
    let manager = CLLocationManager()
    // Update closures... 
}
```

**Use whichever approach ensures `CLLocationManager()` is NOT called until user gesture.**

---

## Files to modify

| File | Action |
|---|---|
| `Shared/LocationPermissionStore.swift` | MODIFY — lazy CLLocationManager init |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- Cold launch must NOT show location permission dialog.
- Location features must still work when user taps the location FAB.
