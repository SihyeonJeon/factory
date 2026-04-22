import SwiftUI

// vibe-limit-checked: 14 reusable avatar stack, 8 44pt/a11y, 7 Korean initials from sample data
struct UnfadingAvatarStack: View {
    let members: [SampleGroupMember]
    let maxDisplay: Int

    init(members: [SampleGroupMember], maxDisplay: Int = 4) {
        self.members = members
        self.maxDisplay = maxDisplay
    }

    var body: some View {
        HStack(spacing: -12) {
            ForEach(Array(members.prefix(maxDisplay))) { member in
                avatar(initial: member.initial)
            }

            if Self.overflowCount(total: members.count, maxDisplay: maxDisplay) > 0 {
                Text("+\(Self.overflowCount(total: members.count, maxDisplay: maxDisplay))")
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .frame(width: 44, height: 44)
                    .background(UnfadingTheme.Color.sheet, in: Circle())
                    .overlay {
                        Circle().stroke(UnfadingTheme.Color.primarySoft, lineWidth: 2)
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UnfadingLocalized.Groups.membersLabel)
    }

    static func overflowCount(total: Int, maxDisplay: Int) -> Int {
        max(0, total - maxDisplay)
    }

    private func avatar(initial: String) -> some View {
        Text(initial)
            .font(UnfadingTheme.Font.footnoteSemibold())
            .foregroundStyle(UnfadingTheme.Color.primary)
            .frame(width: 44, height: 44)
            .background(UnfadingTheme.Color.primarySoft, in: Circle())
            .overlay {
                Circle().stroke(UnfadingTheme.Color.sheet, lineWidth: 2)
            }
    }
}
