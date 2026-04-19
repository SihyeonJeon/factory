# Sprint 7 — Map Themes, Icon Packs & Premium Subscription

**Date:** 2026-04-13
**Prerequisite:** Sprint 6 + Remediation r9 green (69/69 tests)
**Goal:** 3 nice-to-have features + subscription gating. All tests green after.

---

## Feature 1: Map Themes

### Acceptance criteria (from "Nice to have")
- Richer map themes beyond the default.
- Users can switch map visual style per group.

### Implementation spec

1. **`Shared/Domain/MapTheme.swift`** (NEW)
   ```swift
   enum MapTheme: String, Codable, CaseIterable, Identifiable {
       case standard
       case satellite
       case hybrid
       case muted     // custom: desaturated pastel tones
       case dark      // custom: dark-mode optimized
       case vintage   // custom: warm sepia tones

       var id: String { rawValue }
       var displayName: String { ... }
       var mapStyle: MapStyle { ... } // iOS 17+ MapStyle
   }
   ```

2. **`Shared/Domain/GroupStore.swift`** modification
   - Add `@Published var groupMapThemes: [UUID: MapTheme] = [:]`
   - Add `func setMapTheme(_ theme: MapTheme, for groupID: UUID)`
   - Add `func mapTheme(for groupID: UUID) -> MapTheme` (defaults to `.standard`)

3. **`Features/Home/MemoryMapHomeView.swift`** modification
   - Apply `groupStore.mapTheme(for: currentGroupID)` to the Map view
   - Use `.mapStyle()` modifier for standard/satellite/hybrid
   - For custom themes (muted, dark, vintage): apply `.colorScheme` + `.saturation` + `.contrast` modifiers

4. **`Features/Groups/MapThemePickerView.swift`** (NEW)
   - Grid of theme previews (2 columns)
   - Each preview: small Map snapshot with the theme applied + theme name
   - Tap selects theme via `groupStore.setMapTheme()`
   - Show lock icon on premium themes (muted, dark, vintage) if not subscribed

5. **`Features/Groups/GroupHubView.swift`** modification
   - Add "Map Theme" NavigationLink with `systemImage: "map"` for each group
   - Links to `MapThemePickerView(groupID: group.id)`

---

## Feature 2: Premium Icon Packs

### Acceptance criteria (from "Nice to have")
- Premium icon packs for map pins.

### Implementation spec

1. **`Shared/Domain/PinIconPack.swift`** (NEW)
   ```swift
   enum PinIconPack: String, Codable, CaseIterable, Identifiable {
       case standard    // free: default SF Symbols
       case emoji       // free: emoji-based pins
       case minimal     // premium: thin line icons
       case colorful    // premium: vibrant filled icons
       case handDrawn   // premium: sketch-style icons

       var id: String { rawValue }
       var displayName: String { ... }
       var isPremium: Bool { ... }
       func pinImage(for emotion: EmotionTag) -> String { ... } // SF Symbol name
   }
   ```

2. **`Shared/Domain/GroupStore.swift`** modification
   - Add `@Published var groupPinPacks: [UUID: PinIconPack] = [:]`
   - Add `func setPinPack(_ pack: PinIconPack, for groupID: UUID)`
   - Add `func pinPack(for groupID: UUID) -> PinIconPack` (defaults to `.standard`)

3. **`Features/Home/MemoryPinMarker.swift`** modification
   - Read pin icon from `groupStore.pinPack(for: groupID)` instead of hardcoded SF Symbol
   - Apply pack-specific styling (size, color, background shape)

4. **`Features/Groups/PinIconPackPickerView.swift`** (NEW)
   - Grid showing sample pins per pack
   - Lock icon on premium packs if not subscribed
   - Tap selects pack

---

## Feature 3: Premium Subscription Gating

### Acceptance criteria (from "Nice to have")
- Premium customization and advanced rewind behavior under subscription.

### Implementation spec

1. **`Shared/SubscriptionStore.swift`** (NEW)
   ```swift
   @MainActor
   final class SubscriptionStore: ObservableObject {
       @Published private(set) var isPremium: Bool = false

       func checkSubscription() { /* StoreKit 2 placeholder */ }
       func purchase() async { /* StoreKit 2 placeholder */ }
       func restore() async { /* StoreKit 2 placeholder */ }
   }
   ```
   - For MVP: simple boolean toggle, StoreKit 2 integration is placeholder
   - Injected as `@EnvironmentObject` in `MemoryMapApp.swift`

2. **`Features/Settings/PremiumUpgradeView.swift`** (NEW)
   - Feature comparison: free vs premium
   - Premium features: custom map themes (muted/dark/vintage), premium pin packs (minimal/colorful/handDrawn), advanced rewind (weekly digest)
   - "Upgrade" button calls `subscriptionStore.purchase()`
   - "Restore" button calls `subscriptionStore.restore()`

3. **Premium gating in existing views:**
   - `MapThemePickerView` — lock icon + "Upgrade" sheet on premium theme tap
   - `PinIconPackPickerView` — lock icon + "Upgrade" sheet on premium pack tap
   - `DiaryCoverCustomizationView` — all themes free (no change)

4. **`App/MemoryMapApp.swift`** modification
   - Add `.environmentObject(SubscriptionStore())` to the app's scene

### Tests to add
- `testMapThemeDefaultsToStandard` — verify GroupStore returns .standard
- `testSetMapTheme` — set theme to .satellite, verify
- `testPinIconPackDefaultsToStandard` — verify default
- `testSetPinIconPack` — set to .emoji, verify
- `testPremiumPinPacksRequireSubscription` — verify .minimal/.colorful/.handDrawn are premium
- `testSubscriptionStoreDefaultsToFree` — verify isPremium == false

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 69 existing tests must pass. New tests bring total to ~75.
- SubscriptionStore is a placeholder — no real StoreKit calls. Just a boolean for MVP gating.
- Premium themes: muted, dark, vintage (map) and minimal, colorful, handDrawn (pins). Free: standard, satellite, hybrid (map) and standard, emoji (pins).
