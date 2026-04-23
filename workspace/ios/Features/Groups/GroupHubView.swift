import SwiftUI
import UIKit

struct GroupHubView: View {
    @EnvironmentObject private var groupStore: GroupStore
    @State private var toast: String?
    @State private var isRotatingInvite = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                    cover
                    membersSummary
                    membersList
                    inviteCodeRow
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
            Text(groupStore.activeGroup?.name ?? "-")
                .font(UnfadingTheme.Font.title())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            Text(groupStore.mode.koreanTitle)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            if let intro = groupStore.activeGroup?.intro, !intro.isEmpty {
                Text(intro)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            }
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

    private var membersSummary: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            HStack {
                Text(UnfadingLocalized.Groups.membersLabel)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Spacer()
                Text(UnfadingLocalized.Groups.memberCountFormat(groupStore.members.count))
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            UnfadingAvatarStack(members: avatarMembers)
        }
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.card)
    }

    private var membersList: some View {
        VStack(spacing: UnfadingTheme.Spacing.sm) {
            ForEach(avatarMembers) { member in
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

    private var inviteCodeRow: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Groups.inviteCodeLabel)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            HStack(spacing: UnfadingTheme.Spacing.sm) {
                Text(groupStore.activeGroup?.inviteCode ?? "-")
                    .font(UnfadingTheme.Font.title3Bold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                Button {
                    UIPasteboard.general.string = groupStore.activeGroup?.inviteCode
                    toast = UnfadingLocalized.Groups.copyCode
                } label: {
                    Label(UnfadingLocalized.Groups.copyCode, systemImage: "doc.on.doc")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(UnfadingLocalized.Groups.copyCode)

                Button {
                    Task { await rotateInvite() }
                } label: {
                    Label(UnfadingLocalized.Groups.rotateCode, systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(isRotatingInvite || groupStore.activeGroup == nil)
                .accessibilityLabel(UnfadingLocalized.Groups.rotateCode)
            }

            if let toast {
                Text(toast)
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.card)
    }

    private var avatarMembers: [SampleGroupMember] {
        groupStore.members.map { profile in
            let name = profile.displayName ?? "이름 없음"
            return SampleGroupMember(
                id: profile.id,
                name: name,
                initial: String(name.first ?? "?"),
                relation: ""
            )
        }
    }

    private func rotateInvite() async {
        isRotatingInvite = true
        do {
            _ = try await groupStore.rotateInvite()
            toast = UnfadingLocalized.Groups.rotated
        } catch {
            toast = UnfadingLocalized.Groups.actionFailed
        }
        isRotatingInvite = false
    }
}

#Preview {
    GroupHubView()
        .environmentObject(
            GroupStore.preview(
                groups: [
                    DBGroup(
                        id: UUID(),
                        name: "주말 모임",
                        inviteCode: "PREVIEW1",
                        createdAt: Date(),
                        createdBy: UUID(),
                        mode: "group",
                        intro: "함께 남기는 지도",
                        coverColorHex: "#F5998C"
                    )
                ],
                members: [
                    DBProfile(id: UUID(), email: nil, displayName: "시현", photoURL: nil, createdAt: nil),
                    DBProfile(id: UUID(), email: nil, displayName: "민지", photoURL: nil, createdAt: nil)
                ]
            )
        )
}
