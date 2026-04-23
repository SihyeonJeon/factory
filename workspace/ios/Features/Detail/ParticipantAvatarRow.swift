import SwiftUI

struct ParticipantAvatarRow: View {
    let participants: [DBProfile]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UnfadingTheme.Spacing.md) {
                ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                    VStack(spacing: UnfadingTheme.Spacing.xs) {
                        Text(initial(for: participant))
                            .font(UnfadingTheme.Font.sectionTitle())
                            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                            .frame(width: 48, height: 48)
                            .background(UnfadingTheme.Color.memberPalette[index % UnfadingTheme.Color.memberPalette.count], in: Circle())

                        Text(name(for: participant))
                            .font(UnfadingTheme.Font.tag(11))
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                            .lineLimit(1)
                            .frame(width: 64)
                    }
                    .frame(minWidth: 64, minHeight: 76)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(name(for: participant))
                }
            }
            .padding(.vertical, UnfadingTheme.Spacing.xs)
        }
        .accessibilityIdentifier("memory-detail-participant-row")
    }

    private func name(for participant: DBProfile) -> String {
        let displayName = participant.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        return participant.email ?? "멤버"
    }

    private func initial(for participant: DBProfile) -> String {
        String(name(for: participant).prefix(1))
    }
}

#Preview {
    ParticipantAvatarRow(participants: [])
        .padding()
        .background(UnfadingTheme.Color.sheet)
}
