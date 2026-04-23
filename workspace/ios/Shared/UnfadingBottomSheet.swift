import SwiftUI

/// Persistent, draggable 3-snap bottom sheet container for map-like surfaces
/// where the sheet is part of the chrome (not a modal). Snap fractions come
/// from `UnfadingTheme.Sheet` (0.22 / 0.52 / 0.88) per deepsight spec.
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

    /// Returns the snap whose fraction is closest to `fraction`.
    public static func nearest(to fraction: Double) -> BottomSheetSnap {
        Self.ordered.min(by: { abs($0.fraction - fraction) < abs($1.fraction - fraction) }) ?? .default_
    }
}

struct UnfadingBottomSheet<Content: View>: View {
    @Binding var snap: BottomSheetSnap
    @ViewBuilder let content: () -> Content
    @State private var dragOffset: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let fullHeight = proxy.size.height
            let targetHeight = fullHeight * snap.fraction - dragOffset
            let sheetHeight = max(80, min(fullHeight * BottomSheetSnap.expanded.fraction, targetHeight))

            VStack(spacing: 0) {
                handle
                content()
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()
            }
            .frame(maxWidth: .infinity)
            .frame(height: sheetHeight)
            .background(
                UnfadingTheme.Color.sheet,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: UnfadingTheme.Radius.sheet,
                    topTrailingRadius: UnfadingTheme.Radius.sheet
                )
            )
            .shadow(color: UnfadingTheme.Color.shadow, radius: 16, x: 0, y: -4)
            .contentShape(Rectangle())
            .gesture(dragGesture(fullHeight: fullHeight))
            .frame(maxHeight: .infinity, alignment: .bottom)
            .animation(reduceMotion ? nil : .interactiveSpring(response: 0.3, dampingFraction: 0.85), value: snap)
        }
    }

    private var handle: some View {
        Capsule()
            .fill(UnfadingTheme.Color.textTertiary.opacity(0.55))
            .frame(width: 40, height: 4)
            .padding(.top, 10)
            .padding(.bottom, UnfadingTheme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle().inset(by: -16))
            .accessibilityElement()
            .accessibilityLabel(UnfadingLocalized.Accessibility.bottomSheetHandleLabel)
            .accessibilityHint(UnfadingLocalized.Accessibility.bottomSheetHandleHint)
    }

    private func dragGesture(fullHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let endFraction = (fullHeight * snap.fraction - value.translation.height) / fullHeight
                let clamped = min(max(endFraction, UnfadingTheme.Sheet.collapsed * 0.9), UnfadingTheme.Sheet.expanded * 1.05)
                snap = BottomSheetSnap.nearest(to: clamped)
                dragOffset = 0
            }
    }
}
