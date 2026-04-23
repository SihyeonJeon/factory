---
round: round_bottom_sheet_rebuild_r1
stage: coding_1st
status: decided
participants: [codex]
decision_id: 20260423-bottom-sheet-rebuild
contract_hash: 9f0857ddd64bcaab1db22f68581c9afcfcd3735a2fec041917cdbd94a1e24d3f
created_at: 2026-04-23T11:41:23Z
---
# R28 BottomSheet Rebuild Plan

## Context
- Locked acceptance requires BottomSheet snap fractions `0.08 / 0.50 / 1.0`, interpreted against the tab-bar-excluded vertical frame.
- R27 custom shell already owns the root `ZStack` and tab bar zIndex 120, so R28 can lift the sheet bottom anchor above the tab bar.
- Sprint 26 requires scroll ownership and sheet drag ownership to be separated; SwiftUI simultaneous gestures were explicitly rejected in feedback planning.
- Expanded state needs a visible return path through `SheetExpandedHeader` and drag-down fallback.

## Proposal
- Keep `BottomSheetSnap` and `UnfadingBottomSheet` names, but recalculate height as `(screenHeight - tabBarHeight) * snap.fraction` and apply bottom padding `tabBarHeight + safeAreaBottom`.
- Add `SheetScrollCoordinator` as a `UIScrollView` delegate bridge that hosts SwiftUI content and reports `offset`, `isAtTop`, and `downwardDrag`.
- Restrict `DragGesture(minimumDistance: 0)` to the handle and expanded header, then resolve release using velocity-projected nearest snap with spring stiffness 260 / damping 32.
- Move `sheetSnap` ownership to `UnfadingTabShell`; pass binding to Home and use it to hide `ComposeFAB` and expanded map chrome.
- Add `CollapsedSummary` and `SheetExpandedHeader` as reusable Home-local views.

## Counter / Review
- Risk: If the hosted sheet content still contains an inner SwiftUI `ScrollView`, the UIKit bridge will observe the wrong scroll view and Sprint 26 handoff remains unverified. Mitigation: allow `MemorySummaryCard` to render without its internal scroll when embedded in `UnfadingBottomSheet`.
- Risk: A fully expanded sheet with short content cannot exercise "not at top" scroll ownership in UITest. Mitigation: ensure expanded hosted content has a minimum scrollable height while keeping visible content aligned at top.
- Risk: UIKit pan velocity sign differs from the pseudocode comment in the dispatch prompt. Mitigation: use actual UIKit `UIPanGestureRecognizer` semantics where positive y is downward, while preserving `targetContentOffset = .zero` and release-to-sheet only at top.
- Risk: `UIScreen.main.bounds` would be harder to test and less correct inside split-screen or simulator resized contexts. Mitigation: use the local `GeometryReader` screen height in the root shell coordinate space and keep the same formula.

## Convergence
- Proceed with the UIKit delegate bridge and shell-owned snap binding because those are the only options that directly address the real-device feedback blockers without reworking the tab shell again.

## Decision
- Implement R28 in the whitelisted files only.
- Activate the previously skipped snap UITest and add collapsed-above-tabbar, expanded-back, and scroll-does-not-collapse coverage.

## Challenge Section
- Normative challenge: Do not rely on SwiftUI `simultaneousGesture` for the scroll/body split. It was the rejected approach in feedback2 planning and would not give deterministic `contentOffset` or release ownership in real-device scroll physics.
- Normative challenge: Do not compute collapsed position from full-screen bottom. A correct 8% collapsed state is still unusable if the tab bar covers it; the coordinate system must make the tab bar top the sheet bottom anchor.
- Normative challenge: Do not hide the FAB with a separate boolean. The shell needs the exact snap enum to avoid drift between expanded visual state and hit testing.
