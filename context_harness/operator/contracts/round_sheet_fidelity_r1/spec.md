# round_sheet_fidelity_r1 Spec

## Scope

Stream A brings the iOS map sheet and floating chrome into visual alignment with `docs/design-docs/Unfading Prototype.html` lines 780-1100.

## Acceptance Criteria

### F1 Bottom Sheet Snap Fidelity

- Bottom sheet snap fractions are exactly `collapsed: 0.085`, `default: 0.52`, `expanded: 1.0`.
- Expanded sheet is flush with the app frame: top corner radius `0`, shadow `none`, no material or overlay treatment.
- Collapsed sheet preserves the handle plus summary content inside an 8.5% height block.

### F2 Drag And Motion Fidelity

- Drag height follows `currentSnapHeight - translation.height`, clamped to `[collapsedHeight, frameHeight]`.
- Drag end resolves by nearest snap after velocity projection, not by cycle behavior.
- Tap on the non-expanded handle keeps the existing cycle behavior.
- Standard motion uses `interpolatingSpring(stiffness: 260, damping: 32, initialVelocity: velocity.height / 1000)`.
- Reduce Motion uses `.easeInOut(duration: 0.25)`.

### F13 Map Chrome Positioning

- Map navigation title and visible navigation bar are removed from the home map.
- TopChrome is a single group/search row at `top: 54pt`, horizontal inset `14pt`.
- FilterChipBar is at `top: 108pt`, horizontal inset `14pt`.

### F14 Floating Action And Map Controls

- Sheet height is measured from the rendered sheet container.
- FAB is positioned at `right: 18pt`, `bottom: measuredSheetHeight + 18pt`.
- Map controls are positioned at `right: 14pt`, `bottom: measuredSheetHeight + 88pt`.
- Interactive controls maintain at least 44pt touch targets.

## Tests

- Unit tests assert snap fractions, expanded radius/shadow, velocity-aware nearest snap resolution, and map layout constants.
- UI test covers default -> expanded -> default -> collapsed sheet gestures in stub mode.
