import SwiftUI

struct MiniButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void

    init(_ title: String, isPrimary: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UnfadingTheme.Font.captionSemibold())
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, UnfadingTheme.Spacing.xs)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isPrimary ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.textPrimary)
        .background(
            isPrimary ? UnfadingTheme.Color.primary : UnfadingTheme.Color.card,
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous)
                .stroke(isPrimary ? UnfadingTheme.Color.primary : UnfadingTheme.Color.divider, lineWidth: 0.5)
        }
        .contentShape(Rectangle())
    }
}
