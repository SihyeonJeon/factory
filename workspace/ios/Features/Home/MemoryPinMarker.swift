import SwiftUI

struct MemoryPinMarker: View {
    let pin: SampleMemoryPin
    var isSelected: Bool = false
    var isDimmed: Bool = false

    var body: some View {
        VStack(spacing: UnfadingTheme.Spacing.xs) {
            Image(systemName: pin.symbol)
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: 44, height: 44)
                .background(pin.color.gradient, in: Circle())
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(UnfadingTheme.Color.primary.opacity(0.35), lineWidth: 8)
                            .frame(width: 58, height: 58)
                    }
                }
                .shadow(color: UnfadingTheme.Color.pinShadow, radius: 8, y: 4)

            Text(pin.shortLabel)
                .font(UnfadingTheme.Font.caption2Semibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .padding(.vertical, UnfadingTheme.Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .scaleEffect(isSelected ? 1.15 : 1)
        .opacity(isDimmed ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.22), value: isSelected)
        .animation(.easeInOut(duration: 0.22), value: isDimmed)
    }
}
