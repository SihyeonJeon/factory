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

    var accessibilityValue: String {
        switch self {
        case .collapsed: return "collapsed"
        case .default_: return "default"
        case .expanded: return "expanded"
        }
    }
}

enum BottomSheetDragResolution {
    static let velocityProjectionSeconds: CGFloat = 0.08

    static func clampedHeight(_ height: CGFloat, in fullHeight: CGFloat) -> CGFloat {
        min(max(height, fullHeight * CGFloat(BottomSheetSnap.collapsed.fraction)), fullHeight)
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
        let nearest = BottomSheetSnap.nearest(to: projected)
        return nearest.limitedToAdjacentSnap(from: currentSnap)
    }
}

private extension BottomSheetSnap {
    func limitedToAdjacentSnap(from current: BottomSheetSnap) -> BottomSheetSnap {
        guard
            let currentIndex = Self.ordered.firstIndex(of: current),
            let targetIndex = Self.ordered.firstIndex(of: self)
        else { return self }

        let limitedIndex = min(max(targetIndex, currentIndex - 1), currentIndex + 1)
        return Self.ordered[limitedIndex]
    }
}

struct UnfadingBottomSheet<Content: View>: View {
    @Binding var snap: BottomSheetSnap
    var measuredHeight: Binding<CGFloat> = .constant(0)
    @ViewBuilder let content: () -> Content
    @GestureState private var translation: CGFloat = 0
    @State private var interactiveHeight: CGFloat?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let fullHeight = proxy.size.height
            let currentSnapHeight = fullHeight * CGFloat(snap.fraction)
            let liveHeight = interactiveHeight ?? BottomSheetDragResolution.clampedHeight(currentSnapHeight - translation, in: fullHeight)

            VStack(spacing: 0) {
                if snap != .expanded {
                    handle
                }
                content()
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()
            }
            .frame(maxWidth: .infinity)
            .frame(height: liveHeight)
            .background(
                UnfadingTheme.Color.sheet,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: snap.topCornerRadius,
                    topTrailingRadius: snap.topCornerRadius
                )
            )
            .shadow(
                color: snap == .expanded ? .clear : UnfadingTheme.Color.shadow,
                radius: snap.shadowRadius,
                x: 0,
                y: snap == .expanded ? 0 : -4
            )
            .contentShape(Rectangle())
            .gesture(dragGesture(fullHeight: fullHeight))
            .frame(maxHeight: .infinity, alignment: .bottom)
            .accessibilityIdentifier("unfading-bottom-sheet")
            .accessibilityValue(snap.accessibilityValue)
            .onAppear { measuredHeight.wrappedValue = liveHeight }
            .onChange(of: liveHeight) { _, newValue in
                measuredHeight.wrappedValue = newValue
            }
        }
    }

    private var handle: some View {
        Button {
            snapTo(snap.next(), velocityHeight: 0)
        } label: {
            Capsule()
                .fill(UnfadingTheme.Color.primary.opacity(0.4))
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
    }

    private func dragGesture(fullHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
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

    private func snapTo(_ target: BottomSheetSnap, velocityHeight: CGFloat) {
        let animation: Animation = reduceMotion
            ? .easeInOut(duration: 0.25)
            : .interpolatingSpring(
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
