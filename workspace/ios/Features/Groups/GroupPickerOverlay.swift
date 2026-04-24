import SwiftUI

struct GroupPickerOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var groupRotorNamespace
    @EnvironmentObject private var groupStore: GroupStore
    @Binding var isPresented: Bool
    let onCreateGroup: () -> Void
    let onGroupChanged: () -> Void

    var body: some View {
        if isPresented {
            GeometryReader { proxy in
                ZStack {
                    Rectangle()
                        .fill(UnfadingTheme.Color.overlayBackdrop)
                        .background(.ultraThinMaterial)
                        .blur(radius: 4)
                        .ignoresSafeArea()
                        .onTapGesture { close() }

                    card(maxHeight: proxy.size.height * 0.80)
                        .frame(width: min(360, proxy.size.width - (UnfadingTheme.Spacing.lg * 2)))
                        .frame(maxHeight: proxy.size.height * 0.80)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(200)
                .accessibilityIdentifier("group-picker-overlay")
                .accessibilityRotor("그룹 목록") {
                    ForEach(groupRotorEntries) { entry in
                        AccessibilityRotorEntry(LocalizedStringKey(entry.label), id: entry.id, in: groupRotorNamespace)
                    }
                }
                .unfadingUITestRotorMarkers(groupRotorEntries, prefix: "rotor-group-picker")
            }
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private func card(maxHeight: CGFloat) -> some View {
        VStack(spacing: UnfadingTheme.Spacing.lg) {
            header

            ScrollView {
                LazyVStack(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(groupStore.groups) { group in
                        GroupPickerRow(
                            group: group,
                            isActive: group.id == groupStore.activeGroupId,
                            members: members(for: group),
                            rotorNamespace: groupRotorNamespace
                        ) {
                            guard group.id != groupStore.activeGroupId else { return }
                            groupStore.setActive(group.id)
                            onGroupChanged()
                            close()
                        }
                    }
                }
                .padding(.vertical, UnfadingTheme.Spacing.xs)
            }
            .frame(maxHeight: maxHeight - 156)

            Button {
                close()
                onCreateGroup()
            } label: {
                Label(UnfadingLocalized.Groups.pickerCreateNew, systemImage: "plus")
                    .font(UnfadingTheme.Font.body(14))
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay {
                        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                            .stroke(
                                UnfadingTheme.Color.primary.opacity(0.66),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                            )
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("group-picker-create")
        }
        .padding(UnfadingTheme.Spacing.xl)
        .background(UnfadingTheme.Color.sheet, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(style: UnfadingTheme.Shadow.overlay)
        .unfadingSemanticGroup()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text(UnfadingLocalized.Groups.pickerTitle)
                    .font(UnfadingTheme.Font.sectionTitle(18))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Text(UnfadingLocalized.Groups.pickerSubtitle)
                    .font(UnfadingTheme.Font.body(12))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(UnfadingTheme.Color.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Groups.pickerClose)
            .accessibilityIdentifier("group-picker-close")
        }
    }

    private func close() {
        isPresented = false
    }

    private func members(for group: DBGroup) -> [String] {
        guard group.id == groupStore.activeGroupId, !groupStore.memberProfiles.isEmpty else {
            return fallbackInitials(for: group)
        }
        return groupStore.memberProfiles.map { profile in
            let name = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            return String((name?.first ?? "?"))
        }
    }

    private func fallbackInitials(for group: DBGroup) -> [String] {
        group.mode == "couple"
            ? SampleGroup.sampleCouple.members.map(\.initial)
            : SampleGroup.sampleGeneral.members.map(\.initial)
    }

    private var groupRotorEntries: [UnfadingRotorMarkerEntry] {
        groupStore.groups.map { group in
            UnfadingRotorMarkerEntry(id: group.id.uuidString, label: group.name)
        }
    }
}

private struct GroupPickerRow: View {
    let group: DBGroup
    let isActive: Bool
    let members: [String]
    let rotorNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: UnfadingTheme.Spacing.md) {
                avatarStack

                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    HStack(spacing: UnfadingTheme.Spacing.xs) {
                        Text(group.name)
                            .font(UnfadingTheme.Font.sectionTitle(15))
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            .lineLimit(1)
                        modeBadge
                    }

                    Text(subtitle)
                        .font(UnfadingTheme.Font.body(12))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: UnfadingTheme.Spacing.sm)

                if isActive {
                    Image(systemName: "checkmark")
                        .imageScale(.small)
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .frame(width: 22, height: 22)
                        .background(UnfadingTheme.Color.primary, in: Circle())
                }
            }
            .padding(UnfadingTheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(background, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                    .stroke(isActive ? UnfadingTheme.Color.primary : UnfadingTheme.Color.divider, lineWidth: isActive ? 1.5 : 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("group-picker-row-\(group.id.uuidString)")
        .accessibilityRotorEntry(id: group.id.uuidString, in: rotorNamespace)
        .unfadingSemanticGroup()
    }

    private var background: Color {
        isActive ? UnfadingTheme.Color.accentSoft : UnfadingTheme.Color.card
    }

    private var avatarStack: some View {
        let shown = Array(members.prefix(3))
        return ZStack(alignment: .leading) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, initial in
                Text(initial)
                    .font(UnfadingTheme.Font.tag(10.5))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(width: 30, height: 30)
                    .background(UnfadingTheme.Color.memberPalette[index % UnfadingTheme.Color.memberPalette.count], in: Circle())
                    .overlay(Circle().stroke(UnfadingTheme.Color.sheet, lineWidth: 2))
                    .offset(x: CGFloat(index) * 20)
            }

            if members.count > 3 {
                Text("+\(members.count - 3)")
                    .font(UnfadingTheme.Font.tag(10))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(UnfadingTheme.Color.surface, in: Circle())
                    .overlay(Circle().stroke(UnfadingTheme.Color.sheet, lineWidth: 2))
                    .offset(x: CGFloat(shown.count) * 20)
            }
        }
        .frame(width: max(30, 30 + CGFloat(max(0, min(members.count, 4) - 1)) * 20), height: 34, alignment: .leading)
    }

    private var modeBadge: some View {
        Text(group.mode == "couple" ? UnfadingLocalized.Groups.pickerCoupleBadge : UnfadingLocalized.Groups.pickerGroupBadge)
            .font(UnfadingTheme.Font.tag(9.5))
            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.xs)
            .padding(.vertical, UnfadingTheme.Spacing.xxs)
            .background(group.mode == "couple" ? UnfadingTheme.Color.primary : UnfadingTheme.Color.secondary, in: Capsule())
    }

    private var subtitle: String {
        "\(UnfadingLocalized.Groups.pickerMembersFormat(max(members.count, 1))) · \(UnfadingLocalized.Groups.pickerAnniversaryFormat(daysTogether))"
    }

    private var daysTogether: Int {
        let start = group.createdAt ?? Calendar.current.date(byAdding: .day, value: -99, to: Date()) ?? Date()
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(days + 1, 1)
    }
}
