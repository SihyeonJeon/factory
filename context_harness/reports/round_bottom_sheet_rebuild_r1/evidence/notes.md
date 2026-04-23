# R28 BottomSheet Rebuild Evidence Notes

## UIKit Bridge Choice
- Chosen implementation: `SheetScrollCoordinator`, a `UIViewRepresentable` wrapping `UIScrollView` with `UIScrollViewDelegate`.
- Reason: Sprint 26 requires deterministic separation between inner content scroll and sheet snap drag. UIKit exposes `contentOffset`, pan translation, and pan velocity in delegate callbacks; SwiftUI-only gesture composition cannot reliably decide ownership during real-device deceleration and bounce.
- Release rule: when `contentOffset.y <= 0` and the pan is downward, `targetContentOffset` is pinned to `.zero` and ownership is released to the sheet snap resolver.

## Spring Tuning
- Snap release uses `.interpolatingSpring(stiffness: 260, damping: 32, initialVelocity: Double(velocity.height) / 1000)`.
- Reduce Motion fallback is `.easeInOut(duration: 0.25)`.
- Projection horizon is `0.2s`, matching the round dispatch requirement for velocity-projected nearest snap.

## Tab-Bar-Above Coordinate Formula
- Input snap fraction remains `BottomSheetSnap.fraction`.
- Available height is `screenHeight - tabBarHeight`.
- Sheet height is `(screenHeight - tabBarHeight) * snap.fraction`.
- Sheet bottom is lifted by `tabBarHeight + safeAreaBottom`, making the visible bottom anchor the tab bar top rather than the physical screen bottom.

## UITest Activation Scope
- `testMapBottomSheetSnapGestures` is unskipped and now verifies default -> expanded, header back -> default, and default -> collapsed with handle still hittable.
- `testSheetCollapsedHandleIsAboveTabBar` verifies the collapsed handle frame ends above the tab bar frame.
- `testSheetExpandedBackButtonReturnsToDefault` covers the explicit expanded return path.
- `testSheetScrollDoesNotCollapseWhenNotAtTop` expands the sheet, scrolls content down, then swipes down inside the scroll view and asserts snap remains expanded.
