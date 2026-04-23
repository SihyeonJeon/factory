import SwiftUI

struct FieldRow<Content: View>: View {
    let title: String
    let placeState: MemoryComposerState.PlaceState?
    let action: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        placeState: MemoryComposerState.PlaceState? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.placeState = placeState
        self.action = action
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs2) {
            HStack(alignment: .center) {
                Text(title)
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                Spacer(minLength: 0)
                if placeState == .needsConfirm {
                    Text(UnfadingLocalized.Composer.confirmLabel)
                        .font(UnfadingTheme.Font.metaNum(10.5, weight: .bold))
                        .foregroundStyle(UnfadingTheme.Color.primary)
                        .padding(.horizontal, UnfadingTheme.Spacing.xs)
                        .padding(.vertical, UnfadingTheme.Spacing.xxs)
                        .background(UnfadingTheme.Color.accentSoft, in: Capsule())
                }
            }

            Group {
                if let action {
                    Button(action: action) {
                        rowContent
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("field-row-\(title)")
                } else {
                    rowContent
                }
            }
        }
    }

    private var rowContent: some View {
        content()
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(UnfadingTheme.Spacing.md)
            .background(UnfadingTheme.Color.card, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
            .shadow(style: UnfadingTheme.Shadow.card)
            .contentShape(Rectangle())
    }

    private var borderColor: Color {
        switch placeState {
        case .needsConfirm:
            return UnfadingTheme.Color.primary
        default:
            return UnfadingTheme.Color.divider
        }
    }

    private var borderWidth: CGFloat {
        placeState == .needsConfirm ? 2 : 0.5
    }
}
