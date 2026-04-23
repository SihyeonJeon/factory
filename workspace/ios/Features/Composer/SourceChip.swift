import SwiftUI

struct SourceChip: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: UnfadingTheme.Spacing.xxs) {
                Image(systemName: systemImage)
                    .font(UnfadingTheme.Font.sectionTitle(18))
                    .accessibilityHidden(true)
                Text(title)
                    .font(UnfadingTheme.Font.captionSemibold())
            }
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, UnfadingTheme.Spacing.xs)
            .background(UnfadingTheme.Color.card, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
            .shadow(style: UnfadingTheme.Shadow.card)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
