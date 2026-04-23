import SwiftUI

// vibe-limit-checked: 8 44pt/a11y/Dynamic Type, 7 Korean group hub fidelity, 11 sample group mapping, 14 reusable avatar stack
struct GroupHubView: View {
    @StateObject private var store = GroupStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                    cover
                    modePicker
                    membersSummary
                    membersList
                    inviteButton
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Groups.navTitle)
        }
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Groups.coverEyebrow)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            Text(store.currentGroup.name)
                .font(UnfadingTheme.Font.title())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            Text(store.currentGroup.mode.koreanTitle)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            Text(store.currentGroup.coverEmojis.joined(separator: " "))
                .font(UnfadingTheme.Font.title3Bold())
        }
        .padding(UnfadingTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [UnfadingTheme.Color.primary, UnfadingTheme.Color.lavender],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.sheet, style: .continuous)
        )
    }

    private var modePicker: some View {
        Picker(
            UnfadingLocalized.Groups.modePickerLabel,
            selection: Binding(
                get: { store.mode },
                set: { store.setMode($0) }
            )
        ) {
            ForEach(GroupMode.allCases, id: \.self) { mode in
                Text(mode.koreanTitle).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(UnfadingLocalized.Groups.modePickerLabel)
    }

    private var membersSummary: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            HStack {
                Text(UnfadingLocalized.Groups.membersLabel)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Spacer()
                Text(UnfadingLocalized.Groups.memberCountFormat(store.currentGroup.members.count))
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            UnfadingAvatarStack(members: store.currentGroup.members)
        }
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.card)
    }

    private var membersList: some View {
        VStack(spacing: UnfadingTheme.Spacing.sm) {
            ForEach(store.currentGroup.members) { member in
                HStack(spacing: UnfadingTheme.Spacing.md) {
                    Text(member.initial)
                        .font(UnfadingTheme.Font.footnoteSemibold())
                        .foregroundStyle(UnfadingTheme.Color.primary)
                        .frame(width: 44, height: 44)
                        .background(UnfadingTheme.Color.primarySoft, in: Circle())

                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                        Text(member.name)
                            .font(UnfadingTheme.Font.subheadlineSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        Text(member.relation)
                            .font(UnfadingTheme.Font.subheadline())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                    Spacer()
                }
                .frame(minHeight: 44)
                .padding(UnfadingTheme.Spacing.md)
                .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.button, shadow: false)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var inviteButton: some View {
        Button {
        } label: {
            Label(UnfadingLocalized.Groups.inviteCta, systemImage: "person.badge.plus")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.unfadingPrimaryFullWidth)
        .accessibilityHint(UnfadingLocalized.Accessibility.inviteGroupHint)
    }
}

#Preview {
    GroupHubView()
}
