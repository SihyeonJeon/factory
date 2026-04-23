import SwiftUI

struct ParticipantChip: View {
    let member: DBGroupMemberWithProfile
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var displayName: String {
        if let nickname = member.nickname?.trimmingCharacters(in: .whitespacesAndNewlines), !nickname.isEmpty {
            return nickname
        }
        if let name = member.profiles.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return "이름 없음"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: UnfadingTheme.Spacing.xs) {
                Text(initial)
                    .font(UnfadingTheme.Font.metaNum(11, weight: .bold))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(width: 26, height: 26)
                    .background(color, in: Circle())

                Text(displayName)
                    .font(UnfadingTheme.Font.chip())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(UnfadingTheme.Font.metaNum(12, weight: .bold))
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .padding(.leading, UnfadingTheme.Spacing.xxs)
            .padding(.trailing, UnfadingTheme.Spacing.sm)
            .background(
                isSelected ? color.opacity(0.13) : UnfadingTheme.Color.card,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? color : UnfadingTheme.Color.divider, lineWidth: isSelected ? 1.5 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(displayName)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
    }

    private var initial: String {
        String(displayName.prefix(1))
    }
}
