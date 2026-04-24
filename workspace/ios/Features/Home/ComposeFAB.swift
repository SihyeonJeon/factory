import SwiftUI

struct ComposeFAB: View {
    @ScaledMetric(relativeTo: .title3) private var buttonSize: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.title3.weight(.bold))
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    LinearGradient(
                        colors: [UnfadingTheme.Color.primary, UnfadingTheme.Color.primaryHover],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(style: UnfadingTheme.Shadow.activeCard)
        }
        .buttonStyle(ComposeFABButtonStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(UnfadingLocalized.Accessibility.composeTabLabel)
        .accessibilityIdentifier("home-fab")
    }
}

private struct ComposeFABButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.96 : 1))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ComposeFAB {}
        .padding()
        .background(UnfadingTheme.Color.bg)
}
