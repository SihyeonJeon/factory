import SwiftUI

struct UnfadingToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(UnfadingTheme.Font.subheadlineSemibold())
            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .frame(minHeight: 44)
            .background(
                UnfadingTheme.Color.textPrimary,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous)
            )
            .shadow(style: UnfadingTheme.Shadow.card)
            .accessibilityIdentifier("unfading-toast")
    }
}
