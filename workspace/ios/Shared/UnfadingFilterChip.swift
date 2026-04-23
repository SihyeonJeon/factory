import SwiftUI

/// Reusable selectable filter chip. Coral background when selected, cream/card
/// background when not. 44pt minimum tap height. Used in the map filter row
/// (전체 / 데이트 / 여행 / 기념일 / 맛집) per deepsight.
// vibe-limit-checked: 8 chip labels/hints/44pt, 2 reusable asset, 7 visual fidelity
struct UnfadingFilterChip: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, systemImage: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: UnfadingTheme.Spacing.xs + 2) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.small)
                }
                Text(title)
                    .font(UnfadingTheme.Font.footnoteSemibold())
            }
            .padding(.horizontal, UnfadingTheme.Spacing.md + 2)
            .padding(.vertical, UnfadingTheme.Spacing.sm)
            .frame(minHeight: 44)
            .foregroundStyle(foreground)
            .background(
                background,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.chip, style: .continuous)
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: UnfadingTheme.Radius.chip, style: .continuous)
                        .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
                }
            }
            .shadow(
                color: isSelected ? UnfadingTheme.Color.primary.opacity(0.35) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .contentShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.chip, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(UnfadingLocalized.Accessibility.filterChipHint(title: title, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foreground: Color {
        isSelected ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.textPrimary
    }

    private var background: Color {
        isSelected ? UnfadingTheme.Color.primary : UnfadingTheme.Color.sheet
    }
}
