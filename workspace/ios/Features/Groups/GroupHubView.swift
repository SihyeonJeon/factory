import SwiftUI
import UIKit

enum GroupHubDestructiveAction: Identifiable, Equatable {
    case leave
    case delete

    var id: String {
        switch self {
        case .leave: "leave"
        case .delete: "delete"
        }
    }
}

struct GroupHubPresentationState: Equatable {
    var destructiveAction: GroupHubDestructiveAction?

    var showsWarningDialog: Bool {
        destructiveAction != nil
    }
}

private struct GroupHubSharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

enum GroupHubFormatting {
    static func roleLabel(mode: String, isOwner: Bool, isCurrentUser: Bool) -> String {
        let base: String
        if mode == "group" || mode == "general_group" {
            base = isOwner ? UnfadingLocalized.GroupHub.ownerRole : UnfadingLocalized.GroupHub.memberRole
        } else {
            base = UnfadingLocalized.GroupHub.partnerRole
        }

        return isCurrentUser ? "\(base) · \(UnfadingLocalized.GroupHub.youSuffix)" : base
    }

    static func startedAt(_ date: Date?) -> String {
        guard let date else { return "-" }
        return UnfadingLocalized.GroupHub.startedAtFormat(date)
    }
}

struct GroupHubView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var groupStore: GroupStore
    @EnvironmentObject private var memoryStore: MemoryStore
    @EnvironmentObject private var userPreferences: UserPreferences
    @State private var toast: String?
    @State private var isRotatingInvite = false
    @State private var isEditingGroupName = false
    @State private var isEditingNickname = false
    @State private var isShowingGroupPicker = false
    @State private var isShowingQR = false
    @State private var anniversaryNotifications = true
    @State private var rewindNotifications = true
    @State private var memberActivityNotifications = true
    @State private var presentationState = GroupHubPresentationState()
    @State private var editedGroupName = ""
    @State private var editedNickname = ""
    @State private var isSavingGroupName = false
    @State private var isSavingNickname = false
    @State private var isExportingPhotos = false
    @State private var exportProgress = 0.0
    @State private var sharePayload: GroupHubSharePayload?
    private let dataExporter = DataExporter()
    private let photoUploader = PhotoUploader()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                    overviewSection
                    membersSection
                    inviteSection
                    appearanceSection
                    notificationsSection
                    dataSection
                    dangerSection
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
            .background(UnfadingTheme.Color.cream.ignoresSafeArea())
            .navigationTitle(UnfadingLocalized.GroupHub.navTitle)
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
            .confirmationDialog(
                warningTitle,
                isPresented: warningBinding,
                titleVisibility: .visible
            ) {
                Button(UnfadingLocalized.GroupHub.destructiveConfirm, role: .destructive) {
                    toast = UnfadingLocalized.GroupHub.destructivePlaceholder
                    presentationState.destructiveAction = nil
                }
                Button(UnfadingLocalized.Common.cancel, role: .cancel) {
                    presentationState.destructiveAction = nil
                }
            } message: {
                Text(warningMessage)
            }

            GroupPickerOverlay(
                isPresented: $isShowingGroupPicker,
                onCreateGroup: {
                    toast = UnfadingLocalized.Groups.pickerCreateNew
                },
                onGroupChanged: {
                    toast = UnfadingLocalized.GroupHub.switchGroupCTA
                }
            )

            exportProgressOverlay
        }
        .accessibilityIdentifier("group-hub")
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
    }

    private var overviewSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.overviewSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                HStack(alignment: .firstTextBaseline, spacing: UnfadingTheme.Spacing.md) {
                    Text(groupStore.activeGroup?.name ?? "-")
                        .font(UnfadingTheme.Font.title())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
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
                        .buttonStyle(.bordered)
                        .tint(UnfadingTheme.Color.primary)
                        .accessibilityLabel(UnfadingLocalized.Groups.editGroupName)
                    }
                }

                infoRow(
                    title: UnfadingLocalized.Groups.modePickerLabel,
                    value: groupStore.mode.koreanTitle,
                    systemImage: "person.2"
                )
                infoRow(
                    title: UnfadingLocalized.GroupHub.startedAtLabel,
                    value: GroupHubFormatting.startedAt(groupStore.activeGroup?.createdAt),
                    systemImage: "calendar"
                )
                infoRow(
                    title: UnfadingLocalized.Groups.membersLabel,
                    value: UnfadingLocalized.Groups.memberCountFormat(groupStore.members.count, mode: groupStore.mode),
                    systemImage: "person.3"
                )

                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                        isShowingGroupPicker = true
                    }
                } label: {
                    Label(UnfadingLocalized.GroupHub.switchGroupCTA, systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(UnfadingTheme.Color.primary)
                .accessibilityIdentifier("group-hub-switch-group")
            }
        }
    }

    private var membersSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.membersSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                UnfadingAvatarStack(members: avatarMembers)

                ForEach(memberRows) { member in
                    HStack(spacing: UnfadingTheme.Spacing.md) {
                        Text(member.initial)
                            .font(UnfadingTheme.Font.footnoteSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                            .frame(width: 44, height: 44)
                            .background(member.color, in: Circle())

                        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                            Text(member.name)
                                .font(UnfadingTheme.Font.subheadlineSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            Text(member.role)
                                .font(UnfadingTheme.Font.subheadline())
                                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        }

                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .accessibilityElement(children: .combine)
                }

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
        }
    }

    private var inviteSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.inviteSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                Text(UnfadingLocalized.GroupHub.inviteLinkLabel)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)

                Text(inviteLink)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    Button {
                        UIPasteboard.general.string = inviteLink
                        toast = UnfadingLocalized.GroupHub.inviteLinkCopied
                    } label: {
                        Label(UnfadingLocalized.GroupHub.createInviteLink, systemImage: "link")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        isShowingQR.toggle()
                    } label: {
                        Label(UnfadingLocalized.GroupHub.showQRCode, systemImage: "qrcode")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }

                if isShowingQR {
                    qrPlaceholder
                }

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

                toastView
            }
        }
    }

    private var appearanceSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.appearanceSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                ForEach(MapTheme.allCases, id: \.self) { theme in
                    Button {
                        userPreferences.mapTheme = theme
                    } label: {
                        HStack(spacing: UnfadingTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                                Text(theme.title)
                                    .font(UnfadingTheme.Font.subheadlineSemibold())
                                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                                Text(theme.description)
                                    .font(UnfadingTheme.Font.footnote())
                                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                            }

                            Spacer()

                            Image(systemName: userPreferences.mapTheme == theme ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(
                                    userPreferences.mapTheme == theme
                                    ? UnfadingTheme.Color.primary
                                    : UnfadingTheme.Color.textSecondary
                                )
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.title)
                    .accessibilityValue(
                        userPreferences.mapTheme == theme
                        ? UnfadingLocalized.MapTheme.selected
                        : UnfadingLocalized.MapTheme.notSelected
                    )
                    .accessibilityHint(theme.description)
                }

                Text(UnfadingLocalized.MapTheme.footer)
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
        }
    }

    private var notificationsSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.notificationsSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                Toggle(UnfadingLocalized.GroupHub.anniversaryToggle, isOn: $anniversaryNotifications)
                    .frame(minHeight: 44)
                Toggle(UnfadingLocalized.GroupHub.rewindToggle, isOn: $rewindNotifications)
                    .frame(minHeight: 44)
                Toggle(UnfadingLocalized.GroupHub.memberActivityToggle, isOn: $memberActivityNotifications)
                    .frame(minHeight: 44)
            }
        }
    }

    private var dataSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.dataSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                infoRow(
                    title: UnfadingLocalized.GroupHub.iCloudStatusLabel,
                    value: UnfadingLocalized.GroupHub.iCloudStatusReady,
                    systemImage: "icloud"
                )

                Button {
                    Task { await exportJSON() }
                } label: {
                    Label(UnfadingLocalized.GroupHub.exportJSONCTA, systemImage: "doc.text")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await exportPhotos() }
                } label: {
                    Label(UnfadingLocalized.GroupHub.exportPhotosCTA, systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isExportingPhotos)
            }
        }
    }

    private var dangerSection: some View {
        GroupHubCard(title: UnfadingLocalized.GroupHub.dangerSection) {
            VStack(spacing: UnfadingTheme.Spacing.sm) {
                Button(role: .destructive) {
                    presentationState.destructiveAction = .leave
                } label: {
                    Label(UnfadingLocalized.GroupHub.leaveGroupCTA, systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .accessibilityIdentifier("group-hub-leave")

                Button(role: .destructive) {
                    presentationState.destructiveAction = .delete
                } label: {
                    Label(UnfadingLocalized.GroupHub.deleteGroupCTA, systemImage: "trash")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .disabled(!isOwner)
                .accessibilityIdentifier("group-hub-delete")
            }
        }
    }

    private func infoRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: UnfadingTheme.Spacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(width: 24)
            Text(title)
                .font(UnfadingTheme.Font.subheadline())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            Spacer()
            Text(value)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    private var qrPlaceholder: some View {
        VStack(spacing: UnfadingTheme.Spacing.sm) {
            Image(systemName: "qrcode")
                .font(UnfadingTheme.Font.pageTitle(52))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .frame(width: 116, height: 116)
                .background(UnfadingTheme.Color.surface, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
            Text(UnfadingLocalized.GroupHub.qrPlaceholder)
                .font(UnfadingTheme.Font.footnote())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.vertical, UnfadingTheme.Spacing.sm)
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(minHeight: 44, alignment: .leading)
        }
    }

    @ViewBuilder
    private var exportProgressOverlay: some View {
        if isExportingPhotos {
            ZStack {
                UnfadingTheme.Color.textPrimary.opacity(0.14)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                    Text(UnfadingLocalized.GroupHub.exportPhotosProgressTitle)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)

                    ProgressView(value: exportProgress)
                        .tint(UnfadingTheme.Color.primary)

                    Text(UnfadingLocalized.GroupHub.exportPhotosProgressValue(Int((exportProgress * 100).rounded())))
                        .font(UnfadingTheme.Font.footnote())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                .padding(UnfadingTheme.Spacing.lg)
                .frame(maxWidth: 320, alignment: .leading)
                .background(
                    UnfadingTheme.Color.surface,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                )
                .shadow(style: UnfadingTheme.Shadow.overlay)
            }
            .transition(.opacity)
        }
    }

    private var warningBinding: Binding<Bool> {
        Binding(
            get: { presentationState.showsWarningDialog },
            set: { isPresented in
                if !isPresented {
                    presentationState.destructiveAction = nil
                }
            }
        )
    }

    private var warningTitle: String {
        switch presentationState.destructiveAction {
        case .leave:
            return UnfadingLocalized.GroupHub.leaveWarningTitle
        case .delete:
            return UnfadingLocalized.GroupHub.deleteWarningTitle
        case nil:
            return ""
        }
    }

    private var warningMessage: String {
        switch presentationState.destructiveAction {
        case .leave:
            return UnfadingLocalized.GroupHub.leaveWarningMessage
        case .delete:
            return UnfadingLocalized.GroupHub.deleteWarningMessage
        case nil:
            return ""
        }
    }

    private var inviteLink: String {
        UnfadingLocalized.GroupHub.inviteLink(code: groupStore.activeGroup?.inviteCode ?? "-")
    }

    private var memberRows: [GroupHubMemberRowModel] {
        groupStore.members.enumerated().map { index, member in
            let name = groupStore.displayName(for: member.profiles.id)
            let isCurrentUser = member.profiles.id == authStore.currentUserId
            let isMemberOwner = member.profiles.id == groupStore.activeGroup?.createdBy
            return GroupHubMemberRowModel(
                id: member.profiles.id,
                name: name,
                initial: String(name.first ?? "?"),
                role: GroupHubFormatting.roleLabel(
                    mode: groupStore.activeGroup?.mode ?? "group",
                    isOwner: isMemberOwner,
                    isCurrentUser: isCurrentUser
                ),
                color: UnfadingTheme.Color.memberPalette[index % UnfadingTheme.Color.memberPalette.count]
            )
        }
    }

    private var avatarMembers: [SampleGroupMember] {
        memberRows.map { member in
            SampleGroupMember(id: member.id, name: member.name, initial: member.initial, relation: member.role)
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
                        .font(UnfadingTheme.Font.footnote())
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

    private func exportJSON() async {
        do {
            let url = try await dataExporter.exportJSON(memories: memoryStore.memories)
            sharePayload = GroupHubSharePayload(items: [url])
            toast = UnfadingLocalized.GroupHub.exportJSONReady
        } catch {
            toast = error.localizedDescription
        }
    }

    private func exportPhotos() async {
        isExportingPhotos = true
        exportProgress = 0

        do {
            let url = try await dataExporter.exportPhotos(
                memories: memoryStore.memories,
                uploader: photoUploader,
                progress: { progressValue in
                    Task { @MainActor in
                        exportProgress = progressValue
                    }
                }
            )
            sharePayload = GroupHubSharePayload(items: [url])
            toast = UnfadingLocalized.GroupHub.exportPhotosReady
        } catch {
            toast = error.localizedDescription
        }

        isExportingPhotos = false
    }
}

private struct GroupHubMemberRowModel: Identifiable {
    let id: UUID
    let name: String
    let initial: String
    let role: String
    let color: Color
}

private struct GroupHubCard<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(title)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            content
        }
        .padding(UnfadingTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.card)
        .unfadingSemanticGroup()
    }
}

#Preview {
    let ownerId = UUID()
    let secondId = UUID()
    NavigationStack {
        GroupHubView()
            .environmentObject(
                GroupStore.preview(
                    groups: [
                        DBGroup(
                            id: UUID(),
                            name: "주말 모임",
                            inviteCode: "PREVIEW1",
                            createdAt: Date(timeIntervalSince1970: 1_776_000_000),
                            createdBy: ownerId,
                            mode: "group",
                            intro: "함께 남기는 지도",
                            coverColorHex: "#F5998C"
                        )
                    ],
                    members: [
                        DBGroupMemberWithProfile(
                            id: UUID(),
                            nickname: "시현",
                            profiles: DBProfile(id: ownerId, email: nil, displayName: "시현 프로필", photoURL: nil, createdAt: nil)
                        ),
                        DBGroupMemberWithProfile(
                            id: UUID(),
                            nickname: nil,
                            profiles: DBProfile(id: secondId, email: nil, displayName: "민지", photoURL: nil, createdAt: nil)
                        )
                    ]
                )
            )
            .environmentObject(AuthStore(preview: .signedIn(userId: ownerId, email: "preview@example.com")))
            .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
            .environmentObject(UserPreferences())
    }
}
