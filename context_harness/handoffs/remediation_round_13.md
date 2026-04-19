# Remediation Round 13 — Sprint 8-B Design Tone Blockers

**Date:** 2026-04-14
**Source:** Red Team + HIG + Visual QA evaluation — 2 blockers
**Goal:** Fix dark mode enforcement + contrast ratio. All 75 tests must remain green.

---

## Fix B1: Missing `.preferredColorScheme(.light)`

### Problem
`App/UnfadingApp.swift` — The entire design uses explicit light-mode Color literals. Without enforcing `.preferredColorScheme(.light)`, dark mode users get mixed-mode appearance (cream surfaces + dark system UI).

### Implementation
Add `.preferredColorScheme(.light)` to `RootTabView()` in `UnfadingApp.swift`:

```swift
RootTabView(evidenceMode: evidenceMode)
    .preferredColorScheme(.light)    // ADD THIS
    .environmentObject(memoryStore)
    // ... rest of environment objects
```

---

## Fix B2: White text on coral contrast failure

### Problem
Active filter pills and buttons use white foreground text on `UnfadingTheme.primary` (coral #F5998C). Contrast ratio ~2.1:1, below WCAG AA minimum of 3:1 for large text.

### Implementation
Two-part fix:

1. **Deepen the primary coral** in `UnfadingTheme.swift` to a richer terracotta that supports white text:
```swift
// Change primary from soft coral to deeper terracotta
static let primary = Color(red: 0.85, green: 0.42, blue: 0.38)        // #D96B61 — deeper terracotta
static let primaryLight = Color(red: 0.96, green: 0.78, blue: 0.74)   // keep light peach for backgrounds
```

2. **Also update `accent` to match** (since it references primary):
```swift
static let accent = Color(red: 0.85, green: 0.42, blue: 0.38)         // match primary
```

This deeper shade gives white text a contrast ratio of ~4.2:1, well above the 3:1 minimum.

The `primaryLight` stays soft for backgrounds where dark text is used.

---

## Advisory Fix (while here): MemoryPinMarker shadow

Replace `.shadow(color: .black.opacity(0.18), ...)` in `MemoryPinMarker.swift` with `UnfadingTheme.primary.opacity(0.12)` for consistency.

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test` after all edits.
- All 75 tests must pass.
