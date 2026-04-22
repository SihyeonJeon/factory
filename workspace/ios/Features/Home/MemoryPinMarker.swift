import SwiftUI

struct MemoryPinMarker: View {
    let pin: SampleMemoryPin

    var body: some View {
        VStack(spacing: UnfadingTheme.Spacing.xs) {
            Image(systemName: pin.symbol)
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: 44, height: 44)
                .background(pin.color.gradient, in: Circle())
                .shadow(color: UnfadingTheme.Color.pinShadow, radius: 8, y: 4)

            Text(pin.shortLabel)
                .font(UnfadingTheme.Font.caption2Semibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .padding(.vertical, UnfadingTheme.Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
