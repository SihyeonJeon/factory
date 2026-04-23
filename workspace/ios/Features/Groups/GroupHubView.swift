import SwiftUI
import UIKit

struct GroupHubView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var groupStore: GroupStore
    @State private var toast: String?
    @State private var isRotatingInvite = false
    @State private var isEditingGroupName = false
    @State private var isEditingNickname = false
    @State private var editedGroupName = ""
    @State private var editedNickname = ""
    @State private var isSavingGroupName = false
    @State private var isSavingNickname = false

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
            .sheet(isPresented: $isEditingGroupName) {
                editGroupNameSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isEditingNickname) {
                editNicknameSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Groups.coverEyebrow)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            HStack(alignment: .firstTextBaseline, spacing: UnfadingTheme.Spacing.md) {
                Text(groupStore.activeGroup?.name ?? "-")
                    .font(UnfadingTheme.Font.title())
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isOwner {
                    Button {
                        editedGroupName = groupStore.activeGroup?.name ?? ""
                        isEditingGroupName = true
                    } label: {
                        Text(UnfadingLocalized.Groups.edit)
                            .font(UnfadingTheme.Font.captionSemibold())
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(UnfadingTheme.Color.sheet.opacity(0.24))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .accessibilityLabel(UnfadingLocalized.Groups.editGroupName)
                }
            }
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

            Button {
                editedNickname = currentNickname ?? ""
                isEditingNickname = true
            } label: {
                Label(UnfadingLocalized.Groups.editNickname, systemImage: "person.text.rectangle")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint(UnfadingLocalized.Groups.nicknameHint)
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
        groupStore.members.map { member in
            let name = groupStore.displayName(for: member.profiles.id)
            return SampleGroupMember(
                id: member.profiles.id,
                name: name,
                initial: String(name.first ?? "?"),
                relation: ""
            )
        }
    }

    private var isOwner: Bool {
        guard let userId = authStore.currentUserId else { return false }
        return groupStore.activeGroup?.createdBy == userId
    }

    private var currentNickname: String? {
        guard let userId = authStore.currentUserId else { return nil }
        return groupStore.members.first(where: { $0.profiles.id == userId })?.nickname
    }

    private var editGroupNameSheet: some View {
        NavigationStack {
            Form {
                Section(UnfadingLocalized.Groups.editGroupName) {
                    TextField(UnfadingLocalized.Groups.namePlaceholder, text: $editedGroupName)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                        .accessibilityLabel(UnfadingLocalized.Groups.namePlaceholder)
                }
            }
            .navigationTitle(UnfadingLocalized.Groups.editGroupName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        isEditingGroupName = false
                    }
                    .frame(minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(UnfadingLocalized.Common.confirm) {
                        Task { await saveGroupName() }
                    }
                    .disabled(isSavingGroupName || editedGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var editNicknameSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(UnfadingLocalized.Groups.nicknamePlaceholder, text: $editedNickname)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                        .accessibilityLabel(UnfadingLocalized.Groups.nicknamePlaceholder)
                        .accessibilityHint(UnfadingLocalized.Groups.nicknameHint)
                        .onChange(of: editedNickname) { _, newValue in
                            let limited = String(newValue.prefix(40))
                            if limited != newValue {
                                editedNickname = limited
                            }
                        }
                    Text(UnfadingLocalized.Groups.nicknameHint)
                        .font(.caption)
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                } header: {
                    Text(UnfadingLocalized.Groups.editNickname)
                }
            }
            .navigationTitle(UnfadingLocalized.Groups.editNickname)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        isEditingNickname = false
                    }
                    .frame(minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(UnfadingLocalized.Common.confirm) {
                        Task { await saveNickname() }
                    }
                    .disabled(isSavingNickname)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private func saveGroupName() async {
        guard isOwner else {
            toast = UnfadingLocalized.Groups.notOwnerHint
            isEditingGroupName = false
            return
        }

        let trimmed = editedGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSavingGroupName = true
        do {
            try await groupStore.updateGroupName(trimmed)
            toast = UnfadingLocalized.Groups.groupNameUpdated
            isEditingGroupName = false
        } catch {
            toast = UnfadingLocalized.Groups.actionFailed
        }
        isSavingGroupName = false
    }

    private func saveNickname() async {
        isSavingNickname = true
        do {
            try await groupStore.setMyNickname(editedNickname)
            toast = UnfadingLocalized.Groups.nicknameUpdated
            isEditingNickname = false
        } catch {
            toast = UnfadingLocalized.Groups.actionFailed
        }
        isSavingNickname = false
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
                    DBGroupMemberWithProfile(
                        id: UUID(),
                        nickname: "시현",
                        profiles: DBProfile(id: UUID(), email: nil, displayName: "시현 프로필", photoURL: nil, createdAt: nil)
                    ),
                    DBGroupMemberWithProfile(
                        id: UUID(),
                        nickname: nil,
                        profiles: DBProfile(id: UUID(), email: nil, displayName: "민지", photoURL: nil, createdAt: nil)
                    )
                ]
            )
        )
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
}
