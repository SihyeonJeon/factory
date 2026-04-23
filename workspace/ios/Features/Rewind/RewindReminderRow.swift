import SwiftUI

// vibe-limit-checked: 8 Toggle a11y/44pt/Dynamic Type, 7 retention hook surfaced honestly, 14 small reusable row
struct RewindReminderRow: View {
    @State private var isEnabled = false

    var body: some View {
        HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
            Image(systemName: "bell.fill")
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(width: 44, height: 44)
                .background(UnfadingTheme.Color.primarySoft, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Toggle(isOn: $isEnabled) {
                    Text(UnfadingLocalized.Rewind.reminderLabel)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                }
                .frame(minHeight: 44)

                Text(UnfadingLocalized.Rewind.reminderHint)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.card)
    }
}
