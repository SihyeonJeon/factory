# Remediation Round 4 — Sprint 2 P1 Post-Evaluation Fixes

**Date:** 2026-04-13
**Trigger:** Visual QA flagged 1 blocker + 2 mediums after Sprint 2 P1 delivery.
**Goal:** Fix all 3 items, keep 42/42 tests green.

---

## Files in scope

- `workspace/ios/Shared/RewindReminderStore.swift`
- `workspace/ios/Features/Home/MemoryMapHomeView.swift`
- `workspace/ios/Features/Rewind/RewindSettingsView.swift`
- `workspace/ios/Tests/MemoryMapTests.swift` (if tests need updating)

---

## Fixes required

### BLOCKER: Cold-launch notification permission (RewindReminderStore.swift)

**Problem:** `init()` body sets properties that trigger `didSet` observers, which call `requestAuthorization()` + `scheduleNotifications()`. This means the app asks for notification permission immediately on first launch before the user has seen any UI.

**Fix:** Move initial values to **inline property declarations** so `didSet` is NOT triggered during init. Remove the property assignments from the `init()` body entirely.

Example:
```swift
// BEFORE (bad — triggers didSet on init)
@Published var dateReminderEnabled: Bool = false {
    didSet { scheduleNotifications() }
}
init() {
    self.dateReminderEnabled = true  // triggers didSet!
}

// AFTER (correct — inline default, no init body assignment)
@Published var dateReminderEnabled: Bool = true {
    didSet { scheduleNotifications() }
}
// no init() body assignment needed
```

### MEDIUM-1: Time filter chips VoiceOver (MemoryMapHomeView.swift ~lines 278-301)

**Problem:** Filter chip buttons (`All time`, `1 year`, `90 days`, `30 days`) lack VoiceOver accessibility metadata.

**Fix:** Add to each filter chip button:
```swift
.accessibilityLabel("Time filter: \(chipLabel)")
.accessibilityValue(isSelected ? "Selected" : "Not selected")
.accessibilityHint("Double tap to filter memories to \(chipLabel)")
```

### MEDIUM-2: Radius Slider VoiceOver (RewindSettingsView.swift lines 33-37)

**Problem:** The location radius Slider lacks VoiceOver metadata.

**Fix:** Add:
```swift
.accessibilityLabel("Reminder radius")
.accessibilityValue("\(Int(locationRadiusMeters)) meters")
```

### MINOR: FAB scaling (MemoryMapHomeView.swift ~line 535)

**Problem:** Floating action button uses hardcoded 60x60 frame that doesn't scale with Accessibility type sizes.

**Fix:** Use `@ScaledMetric` for the size:
```swift
@ScaledMetric(relativeTo: .title) private var fabSize: CGFloat = 60
// then use .frame(width: fabSize, height: fabSize)
```

---

## Constraints

- Do NOT add new files.
- Do NOT change any public API or type signatures.
- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 42 existing tests must still pass.
