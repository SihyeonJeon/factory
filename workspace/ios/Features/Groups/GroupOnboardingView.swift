import SwiftUI

struct GroupOnboardingView: View {
    @EnvironmentObject private var groupStore: GroupStore

    @State private var selectedTab: Tab = .create
    @State private var name = ""
    @State private var mode: GroupMode = .couple
    @State private var intro = ""
    @State private var code = ""
    @State private var nickname = ""
    @State private var banner: String?
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                    Picker(UnfadingLocalized.Groups.onboardingTitle, selection: $selectedTab) {
                        Text(UnfadingLocalized.Groups.createTab).tag(Tab.create)
                        Text(UnfadingLocalized.Groups.joinTab).tag(Tab.join)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel(UnfadingLocalized.Groups.onboardingTitle)

                    if let banner {
                        statusText(banner, color: UnfadingTheme.Color.primary)
                    }

                    if let errorMessage {
                        statusText(errorMessage, color: UnfadingTheme.Color.textSecondary)
                    }

                    switch selectedTab {
                    case .create:
                        createForm
                    case .join:
                        joinForm
                    }
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Groups.onboardingTitle)
        }
    }

    private var createForm: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
            TextField(UnfadingLocalized.Groups.namePlaceholder, text: $name)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 44)
                .accessibilityLabel(UnfadingLocalized.Groups.namePlaceholder)
                .accessibilityIdentifier("group-name-field")

            Picker(UnfadingLocalized.Groups.modePickerLabel, selection: $mode) {
                Text(UnfadingLocalized.Groups.modeCouple).tag(GroupMode.couple)
                Text(UnfadingLocalized.Groups.modeGroup).tag(GroupMode.general)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(UnfadingLocalized.Groups.modePickerLabel)

            TextField(UnfadingLocalized.Groups.introPlaceholder, text: $intro, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(UnfadingLocalized.Groups.introPlaceholder)

            nicknameField

            Button {
                Task { await createGroup() }
            } label: {
                Text(UnfadingLocalized.Groups.createButton)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.unfadingPrimaryFullWidth)
            .disabled(isSubmitting || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(UnfadingLocalized.Groups.createButton)
            .accessibilityIdentifier("group-create-button")
        }
    }

    private var joinForm: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
            TextField(UnfadingLocalized.Groups.codePlaceholder, text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 44)
                .accessibilityLabel(UnfadingLocalized.Groups.codePlaceholder)
                .accessibilityIdentifier("group-code-field")
                .onChange(of: code) { _, newValue in
                    let normalized = String(newValue.uppercased().prefix(8))
                    if normalized != newValue {
                        code = normalized
                    }
                }

            nicknameField

            Button {
                Task { await joinGroup() }
            } label: {
                Text(UnfadingLocalized.Groups.joinButton)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.unfadingPrimaryFullWidth)
            .disabled(isSubmitting || code.count != 8)
            .accessibilityLabel(UnfadingLocalized.Groups.joinButton)
            .accessibilityIdentifier("group-join-button")
        }
    }

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            TextField(UnfadingLocalized.Groups.nicknamePlaceholder, text: $nickname)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 44)
                .accessibilityLabel(UnfadingLocalized.Groups.nicknamePlaceholder)
                .accessibilityHint(UnfadingLocalized.Groups.nicknameHint)
                .onChange(of: nickname) { _, newValue in
                    let limited = String(newValue.prefix(40))
                    if limited != newValue {
                        nickname = limited
                    }
                }

            Text(UnfadingLocalized.Groups.nicknameHint)
                .font(.caption)
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
        }
    }

    private func statusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(UnfadingTheme.Font.subheadlineSemibold())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .background(UnfadingTheme.Color.sheet, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private func createGroup() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil
        do {
            let trimmedIntro = intro.trimmingCharacters(in: .whitespacesAndNewlines)
            try await groupStore.createGroup(
                name: trimmedName,
                mode: mode,
                intro: trimmedIntro.isEmpty ? nil : trimmedIntro,
                nickname: normalizedNickname
            )
            banner = UnfadingLocalized.Groups.createdBanner
        } catch {
            errorMessage = UnfadingLocalized.Groups.actionFailed + errorSuffix(for: error)
            #if DEBUG
            print("GroupOnboarding createGroup error:", error)
            #endif
        }
        isSubmitting = false
    }

    private func joinGroup() async {
        guard code.count == 8 else {
            errorMessage = UnfadingLocalized.Groups.invalidCode
            return
        }

        isSubmitting = true
        errorMessage = nil
        do {
            try await groupStore.joinGroup(code: code, nickname: normalizedNickname)
            banner = UnfadingLocalized.Groups.joinedBanner
        } catch {
            errorMessage = UnfadingLocalized.Groups.actionFailed + errorSuffix(for: error)
            #if DEBUG
            print("GroupOnboarding joinGroup error:", error)
            #endif
        }
        isSubmitting = false
    }

    private var normalizedNickname: String? {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func errorSuffix(for error: Error) -> String {
        let raw = String(describing: error)
        return " (\(String(raw.prefix(120))))"
    }

    private enum Tab: Hashable {
        case create
        case join
    }
}

#Preview {
    GroupOnboardingView()
        .environmentObject(GroupStore.preview())
}
