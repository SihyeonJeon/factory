# round_sheet_fidelity_r1 Evidence Notes

## Drag Gesture

- `UnfadingBottomSheet` uses `@GestureState` for vertical translation and a live interactive height state during drag.
- Drag height is computed as `currentSnapHeight - translation.height` and clamped to collapsed height through full frame height.
- Release computes a velocity-projected fraction, chooses the nearest snap, then limits movement to one adjacent snap per gesture to prevent accidental expanded-to-collapsed jumps.
- Handle tap keeps the existing cycle behavior for collapsed -> default -> expanded -> collapsed, but the handle is not rendered in expanded state.

## Spring Tuning

- Initial spring value: `interpolatingSpring(stiffness: 260, damping: 32, initialVelocity: Double(velocityHeight) / 1000)`.
- This is intended to approximate the prototype's `height 340ms cubic-bezier(0.32, 0.72, 0, 1)` with a native iOS velocity-aware spring.
- Reduce Motion fallback is `.easeInOut(duration: 0.25)`.
- QA tuning note: if runtime capture looks slower or bouncier than the HTML prototype, raise damping in `0.5` increments and recapture.

## Sheet Height Measurement

- The sheet container computes its rendered height inside its `GeometryReader`.
- `MemoryMapHomeView` receives the rendered height through a `Binding<CGFloat>` and stores it locally because `MemorySelectionState.swift` is not part of Stream A's whitelist.
- FAB uses `measuredSheetHeight + 18pt`; map controls use `measuredSheetHeight + 88pt`.

## QA Checks

- Collapsed state must show the handle and summary content clipped into an 8.5% height block.
- Expanded state must be flush to the top with zero sheet corner radius and no shadow.
- TopChrome should sit at 54pt with only one group/search row.
- FilterChipBar should sit at 108pt.
- FAB and map controls should track the measured sheet height during snap animation.
- `project.yml` was intentionally not modified; xcodegen/test execution is deferred to the merge operator.
