# round_overlays_r1 Evidence Notes

- Backdrop implementation: both overlays use SwiftUI `.overlay` + internal `ZStack`, with `UnfadingTheme.Color.overlayBackdrop`, `.background(.ultraThinMaterial)`, and `.blur(radius: 4)` behind the card. Native `.sheet` was not used because the handoff requires a custom full-frame backdrop and exact card styling.
- Two-overlay rule: `UnfadingTabShell` owns `showingGroupPicker` and `showingCategoryEditor`; each `onChange` closes the other overlay when one opens.
- Category duplicate handling: `CategoryStore.add(name:icon:)` trims input and throws `CategoryError.duplicateName` for case-insensitive duplicate names. `CategoryEditorOverlay` shows the localized duplicate error inline and does not persist the duplicate.
- Group switch reset: tapping an inactive picker row calls `GroupStore.setActive(_:)`, increments the shell reset token, clears home pin/category selection, resets the sheet snap to `.default_`, then closes the overlay.
