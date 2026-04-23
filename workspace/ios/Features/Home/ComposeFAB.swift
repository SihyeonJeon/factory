import SwiftUI

struct ComposeFAB: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: 56, height: 56)
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
        .buttonStyle(.plain)
        .accessibilityLabel(UnfadingLocalized.Accessibility.composeTabLabel)
        .accessibilityIdentifier("home-fab")
    }
}

#Preview {
    ComposeFAB {}
        .padding()
        .background(UnfadingTheme.Color.bg)
}
