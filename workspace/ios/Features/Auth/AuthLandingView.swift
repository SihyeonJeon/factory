import SwiftUI

struct AuthLandingView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case signIn
        case signUp

        var id: String { rawValue }

        var title: String {
            switch self {
            case .signIn: return UnfadingLocalized.Auth.signInTab
            case .signUp: return UnfadingLocalized.Auth.signUpTab
            }
        }
    }

    @EnvironmentObject private var authStore: AuthStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isShowingResetSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                UnfadingTheme.Color.cream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                        header
                        modePicker
                        form
                    }
                    .padding(.horizontal, UnfadingTheme.Spacing.xl)
                    .padding(.vertical, UnfadingTheme.Spacing.xxl)
                }
            }
            .sheet(isPresented: $isShowingResetSheet) {
                ResetPasswordSheet(initialEmail: email)
                    .environmentObject(authStore)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text(UnfadingLocalized.Auth.welcomeTitle)
                .font(UnfadingTheme.Font.title())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            Text(UnfadingLocalized.Auth.welcomeSubtitle)
                .font(UnfadingTheme.Font.subheadline())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var modePicker: some View {
        Picker(UnfadingLocalized.Auth.modePickerLabel, selection: $mode) {
            ForEach(Mode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(minHeight: 44)
        .accessibilityIdentifier("auth-mode-picker")
        .accessibilityLabel(UnfadingLocalized.Auth.modePickerLabel)
        .onChange(of: mode) { _, _ in
            errorMessage = nil
        }
    }

    private var form: some View {
        VStack(spacing: UnfadingTheme.Spacing.lg) {
            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }

            VStack(spacing: UnfadingTheme.Spacing.md) {
                TextField(UnfadingLocalized.Auth.emailPlaceholder, text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                    .accessibilityIdentifier("auth-email")
                    .accessibilityLabel(UnfadingLocalized.Auth.emailPlaceholder)
                    .authFieldStyle()

                SecureField(UnfadingLocalized.Auth.passwordPlaceholder, text: $password)
                    .textContentType(mode == .signIn ? .password : .newPassword)
                    .submitLabel(.go)
                    .accessibilityIdentifier("auth-password")
                    .accessibilityLabel(UnfadingLocalized.Auth.passwordPlaceholder)
                    .authFieldStyle()
            }

            Button(action: submit) {
                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    if isLoading {
                        ProgressView()
                            .tint(UnfadingTheme.Color.textOnPrimary)
                            .accessibilityHidden(true)
                    }
                    Text(mode == .signIn ? UnfadingLocalized.Auth.signInPrimary : UnfadingLocalized.Auth.signUpPrimary)
                }
            }
            .buttonStyle(.unfadingPrimaryFullWidth)
            .disabled(isLoading)
            .opacity(isLoading ? 0.75 : 1)
            .accessibilityIdentifier("auth-primary-button")
            .accessibilityLabel(mode == .signIn ? UnfadingLocalized.Auth.signInPrimary : UnfadingLocalized.Auth.signUpPrimary)
            .accessibilityHint(UnfadingLocalized.Auth.primaryHint)

            Button {
                isShowingResetSheet = true
            } label: {
                Text(UnfadingLocalized.Auth.forgotPassword)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .accessibilityLabel(UnfadingLocalized.Auth.forgotPassword)
            .accessibilityHint(UnfadingLocalized.Auth.forgotPasswordHint)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: errorMessage)
    }

    private func submit() {
        errorMessage = nil
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Self.isValidEmail(normalizedEmail) else {
            errorMessage = UnfadingLocalized.Auth.invalidCredentials
            return
        }

        guard password.count >= 8 else {
            errorMessage = UnfadingLocalized.Auth.passwordTooShort
            return
        }

        isLoading = true
        Task {
            do {
                switch mode {
                case .signIn:
                    try await authStore.signIn(email: normalizedEmail, password: password)
                case .signUp:
                    try await authStore.signUp(email: normalizedEmail, password: password)
                }
            } catch {
                errorMessage = Self.localizedError(for: error)
            }
            isLoading = false
        }
    }

    fileprivate static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private static func localizedError(for error: Error) -> String {
        let message = String(describing: error).lowercased()
        if message.contains("invalid") || message.contains("credential") || message.contains("password") {
            return UnfadingLocalized.Auth.invalidCredentials
        }
        return UnfadingLocalized.Auth.networkError
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(UnfadingTheme.Font.subheadlineSemibold())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .background(
                UnfadingTheme.Color.primarySoft,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous)
            )
            .accessibilityLabel(message)
    }
}

private struct ResetPasswordSheet: View {
    @EnvironmentObject private var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var message: String?
    @State private var isLoading = false

    init(initialEmail: String) {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
                TextField(UnfadingLocalized.Auth.emailPlaceholder, text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .accessibilityLabel(UnfadingLocalized.Auth.emailPlaceholder)
                    .authFieldStyle()

                if let message {
                    ErrorBanner(message: message)
                }

                Button(action: submit) {
                    HStack(spacing: UnfadingTheme.Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .tint(UnfadingTheme.Color.textOnPrimary)
                                .accessibilityHidden(true)
                        }
                        Text(UnfadingLocalized.Auth.forgotPasswordSubmit)
                    }
                }
                .buttonStyle(.unfadingPrimaryFullWidth)
                .disabled(isLoading)
                .accessibilityLabel(UnfadingLocalized.Auth.forgotPasswordSubmit)
                .accessibilityHint(UnfadingLocalized.Auth.forgotPasswordHint)

                Spacer()
            }
            .padding(UnfadingTheme.Spacing.xl)
            .navigationTitle(UnfadingLocalized.Auth.forgotPassword)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        dismiss()
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel(UnfadingLocalized.Common.cancel)
                }
            }
        }
    }

    private func submit() {
        message = nil
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard AuthLandingView.isValidEmail(normalizedEmail) else {
            message = UnfadingLocalized.Auth.invalidCredentials
            return
        }

        isLoading = true
        Task {
            do {
                try await authStore.resetPassword(email: normalizedEmail)
                message = UnfadingLocalized.Auth.emailSent
            } catch {
                message = UnfadingLocalized.Auth.networkError
            }
            isLoading = false
        }
    }
}

private extension View {
    func authFieldStyle() -> some View {
        self
            .font(UnfadingTheme.Font.subheadline())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .frame(minHeight: 52)
            .background(
                UnfadingTheme.Color.surface,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous)
                    .stroke(UnfadingTheme.Color.textTertiary.opacity(0.35), lineWidth: 1)
            )
    }
}

#Preview {
    AuthLandingView()
        .environmentObject(AuthStore(preview: .signedOut))
}
