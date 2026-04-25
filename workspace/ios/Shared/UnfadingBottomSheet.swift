import SwiftUI

/// Persistent, draggable 3-snap bottom sheet container for map-like surfaces
/// where the sheet is part of the chrome (not a modal). Snap fractions mirror
/// the current Unfading design handoff.
///
/// Usage:
///   ```swift
///   @State private var snap: BottomSheetSnap = .default_
///   ZStack {
///       mapContent
///       UnfadingBottomSheet(snap: $snap) { MemorySummaryCard() }
///   }
///   ```
public enum BottomSheetSnap: CaseIterable, Hashable {
    case collapsed
    case `default_`
    case expanded

    /// Snap-point fraction of the container height.
    public var fraction: Double {
        switch self {
        case .collapsed: return UnfadingTheme.Sheet.collapsed
        case .default_: return UnfadingTheme.Sheet.default
        case .expanded: return UnfadingTheme.Sheet.expanded
        }
    }

    /// Ordering used by drag-release snapping logic.
    public static let ordered: [BottomSheetSnap] = [.collapsed, .default_, .expanded]

    public var topCornerRadius: CGFloat {
        self == .expanded ? 0 : UnfadingTheme.Radius.sheet
    }

    public var shadowRadius: CGFloat {
        self == .expanded ? 0 : 16
    }

    /// Returns the snap whose fraction is closest to `fraction`.
    public static func nearest(to fraction: Double) -> BottomSheetSnap {
        Self.ordered.min(by: { abs($0.fraction - fraction) < abs($1.fraction - fraction) }) ?? .default_
    }

    public func next() -> BottomSheetSnap {
        switch self {
        case .collapsed: return .default_
        case .default_: return .expanded
        case .expanded: return .collapsed
        }
    }

    public func previous() -> BottomSheetSnap {
        switch self {
        case .collapsed: return .collapsed
        case .default_: return .collapsed
        case .expanded: return .default_
        }
    }

    var accessibilityValue: String {
        switch self {
        case .collapsed: return "collapsed"
        case .default_: return "default"
        case .expanded: return "expanded"
        }
    }
}

enum BottomSheetDragResolution {
    static let velocityProjectionSeconds: CGFloat = 0.2
    static let velocitySnapThreshold: CGFloat = 600

    static func clampedHeight(_ height: CGFloat, in fullHeight: CGFloat) -> CGFloat {
        min(max(height, fullHeight * CGFloat(BottomSheetSnap.collapsed.fraction)), fullHeight)
    }

    static func availableHeight(
        screenHeight: CGFloat,
        tabBarHeight: CGFloat,
        topSafeArea: CGFloat,
        snap: BottomSheetSnap
    ) -> CGFloat {
        if snap == .expanded {
            return max(screenHeight + topSafeArea, 1)
        }

        return max(screenHeight - tabBarHeight, 1)
    }

    static func projectedFraction(
        currentSnap: BottomSheetSnap,
        translationHeight: CGFloat,
        velocityHeight: CGFloat,
        fullHeight: CGFloat
    ) -> Double {
        guard fullHeight > 0 else { return currentSnap.fraction }
        let currentHeight = fullHeight * CGFloat(currentSnap.fraction)
        let projectedHeight = currentHeight - translationHeight - (velocityHeight * velocityProjectionSeconds)
        return Double(clampedHeight(projectedHeight, in: fullHeight) / fullHeight)
    }

    static func resolvedSnap(
        currentSnap: BottomSheetSnap,
        translationHeight: CGFloat,
        velocityHeight: CGFloat,
        fullHeight: CGFloat
    ) -> BottomSheetSnap {
        let projected = projectedFraction(
            currentSnap: currentSnap,
            translationHeight: translationHeight,
            velocityHeight: velocityHeight,
            fullHeight: fullHeight
        )
        let nearestProjected = BottomSheetSnap.nearest(to: projected)
        let ordered = BottomSheetSnap.ordered
        guard
            let currentIndex = ordered.firstIndex(of: currentSnap),
            let projectedIndex = ordered.firstIndex(of: nearestProjected)
        else {
            return nearestProjected
        }

        let isFastFling = abs(velocityHeight) >= velocitySnapThreshold
        if velocityHeight < 0 {
            if currentIndex == ordered.index(before: ordered.endIndex) { return currentSnap }
            if isFastFling || projectedIndex > currentIndex {
                return ordered[currentIndex + 1]
            }
        } else if velocityHeight > 0 {
            if currentIndex == ordered.startIndex { return currentSnap }
            if isFastFling || projectedIndex < currentIndex {
                return ordered[currentIndex - 1]
            }
        }

        return nearestProjected
    }
}

struct UnfadingBottomSheet<Content: View>: View {
    @Binding var snap: BottomSheetSnap
    var measuredHeight: Binding<CGFloat> = .constant(0)
    var tabBarHeight: CGFloat = 83
    @ViewBuilder let content: () -> Content
    private let collapsedSummary: () -> AnyView
    private let expandedHeader: (_ collapseToDefault: @escaping () -> Void) -> AnyView
    @GestureState private var translation: CGFloat = 0
    @State private var interactiveHeight: CGFloat?
    @State private var scrollOffset: CGPoint = .zero
    @State private var isScrollAtTop = true
    @State private var downwardScrollDrag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init<CollapsedSummaryContent: View, ExpandedHeaderContent: View>(
        snap: Binding<BottomSheetSnap>,
        measuredHeight: Binding<CGFloat> = .constant(0),
        tabBarHeight: CGFloat = 83,
        @ViewBuilder collapsedSummary: @escaping () -> CollapsedSummaryContent,
        @ViewBuilder expandedHeader: @escaping (_ collapseToDefault: @escaping () -> Void) -> ExpandedHeaderContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._snap = snap
        self.measuredHeight = measuredHeight
        self.tabBarHeight = tabBarHeight
        self.content = content
        self.collapsedSummary = { AnyView(collapsedSummary()) }
        self.expandedHeader = { collapseToDefault in AnyView(expandedHeader(collapseToDefault)) }
    }

    init(
        snap: Binding<BottomSheetSnap>,
        measuredHeight: Binding<CGFloat> = .constant(0),
        tabBarHeight: CGFloat = 83,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            snap: snap,
            measuredHeight: measuredHeight,
            tabBarHeight: tabBarHeight,
            collapsedSummary: { EmptyView() },
            expandedHeader: { _ in EmptyView() },
            content: content
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let screenHeight = proxy.size.height
            let availableHeight = BottomSheetDragResolution.availableHeight(
                screenHeight: screenHeight,
                tabBarHeight: tabBarHeight,
                topSafeArea: proxy.safeAreaInsets.top,
                snap: snap
            )
            let bottomInset = tabBarHeight + proxy.safeAreaInsets.bottom
            let currentSnapHeight = availableHeight * CGFloat(snap.fraction)
            let liveHeight = interactiveHeight ?? BottomSheetDragResolution.clampedHeight(currentSnapHeight - translation, in: availableHeight)
            let isExpanded = snap == .expanded

            VStack(spacing: 0) {
                if !isExpanded {
                    handle(fullHeight: availableHeight)
                    if snap == .collapsed {
                        collapsedSummary()
                            .padding(.horizontal, UnfadingTheme.Spacing.lg)
                            .padding(.bottom, UnfadingTheme.Spacing.sm)
                            .transition(.opacity)
                    }
                }

                ZStack(alignment: .top) {
                    SheetScrollCoordinator(
                        offset: $scrollOffset,
                        isAtTop: $isScrollAtTop,
                        downwardDrag: $downwardScrollDrag,
                        onReleaseToSheet: { velocityY in
                            releaseScrollOwnershipToSheet(velocityHeight: velocityY)
                        }
                    ) {
                        content()
                            .padding(.top, isExpanded ? SheetExpandedHeader.totalHeight : 0)
                            .frame(minHeight: isExpanded ? availableHeight + 180 : nil, alignment: .top)
                    }
                    .accessibilityIdentifier("unfading-bottom-sheet-scroll")

                    if isExpanded {
                        expandedHeader {
                            snapTo(.default_, velocityHeight: 0)
                        }
                        .opacity(isExpanded ? 1 : 0)
                        .transition(.opacity)
                        .zIndex(55)
                        .gesture(dragGesture(fullHeight: availableHeight))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()
            }
            .frame(maxWidth: .infinity)
            .frame(height: liveHeight)
            .background {
                if isExpanded {
                    UnfadingTheme.Color.sheet
                        .ignoresSafeArea(.container, edges: .top)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: snap.topCornerRadius,
                                topTrailingRadius: snap.topCornerRadius
                            )
                        )
                } else {
                    UnfadingTheme.Color.sheet
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: snap.topCornerRadius,
                                topTrailingRadius: snap.topCornerRadius
                            )
                        )
                }
            }
            .shadow(
                color: snap == .expanded ? .clear : UnfadingTheme.Color.shadow,
                radius: snap.shadowRadius,
                x: 0,
                y: snap == .expanded ? 0 : -4
            )
            .contentShape(Rectangle())
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, bottomInset)
            .accessibilityIdentifier("unfading-bottom-sheet")
            .accessibilityValue(snap.accessibilityValue)
            .onAppear { measuredHeight.wrappedValue = liveHeight }
            .onChange(of: liveHeight) { _, newValue in
                measuredHeight.wrappedValue = newValue
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: snap == .expanded)
        }
    }

    private func handle(fullHeight: CGFloat) -> some View {
        Button {
            snapTo(snap.next(), velocityHeight: 0)
        } label: {
            Capsule()
                .fill(UnfadingTheme.Color.textPrimary.opacity(0.2))
                .frame(width: 42, height: 5)
                .padding(.top, snap == .collapsed ? 8 : 10)
                .padding(.bottom, snap == .collapsed ? 6 : 8)
        }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityIdentifier("unfading-bottom-sheet-handle")
            .accessibilityElement()
            .accessibilityLabel(UnfadingLocalized.Accessibility.bottomSheetHandleLabel)
            .accessibilityHint(UnfadingLocalized.Accessibility.bottomSheetHandleHint)
            .accessibilityHidden(snap == .expanded)
            .gesture(dragGesture(fullHeight: fullHeight))
    }

    private func dragGesture(fullHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($translation) { value, state, _ in
                state = value.translation.height
            }
            .onChanged { value in
                let currentSnapHeight = fullHeight * CGFloat(snap.fraction)
                interactiveHeight = BottomSheetDragResolution.clampedHeight(currentSnapHeight - value.translation.height, in: fullHeight)
            }
            .onEnded { value in
                let velocityHeight = value.predictedEndTranslation.height - value.translation.height
                let target = BottomSheetDragResolution.resolvedSnap(
                    currentSnap: snap,
                    translationHeight: value.translation.height,
                    velocityHeight: velocityHeight,
                    fullHeight: fullHeight
                )
                snapTo(target, velocityHeight: velocityHeight)
            }
    }

    private func releaseScrollOwnershipToSheet(velocityHeight: CGFloat) {
        guard isScrollAtTop || scrollOffset.y <= 0 else { return }
        let target = snap.previous()
        guard target != snap else { return }
        snapTo(target, velocityHeight: velocityHeight)
    }

    private func snapTo(_ target: BottomSheetSnap, velocityHeight: CGFloat) {
        if reduceMotion {
            snap = target
            interactiveHeight = nil
            return
        }

        let animation = Animation.interpolatingSpring(
            stiffness: 260,
            damping: 32,
            initialVelocity: Double(velocityHeight) / 1000
        )

        withAnimation(animation) {
            snap = target
            interactiveHeight = nil
        }
    }
}
