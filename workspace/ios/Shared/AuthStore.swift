import Foundation
import Supabase

enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(userId: UUID, email: String?)
}

@MainActor
final class AuthStore: ObservableObject {
    @Published var state: AuthState = .unknown

    private var authTask: Task<Void, Never>?
    private let mode: Mode

    static var isUITestAuthStubEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_AUTH_STUB")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST_AUTH_STUB"] == "1"
    }

    init() {
        self.mode = .live
        authTask = Task { [weak self] in
            await self?.start()
        }
    }

    #if DEBUG
    init(preview state: AuthState) {
        self.mode = .preview
        self.state = state
    }
    #endif

    deinit {
        authTask?.cancel()
    }

    func signUp(email: String, password: String) async throws {
        guard mode == .live else { return }
        try await SupabaseService.shared.client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        guard mode == .live else { return }
        try await SupabaseService.shared.client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        guard mode == .live else {
            state = .signedOut
            return
        }

        try await SupabaseService.shared.client.auth.signOut()
        state = .signedOut
    }

    func resetPassword(email: String) async throws {
        guard mode == .live else { return }
        try await SupabaseService.shared.client.auth.resetPasswordForEmail(email)
    }

    private func start() async {
        if Self.isUITestAuthStubEnabled {
            state = .signedIn(
                userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
                email: "uitest@example.com"
            )
            return
        }

        if ProcessInfo.processInfo.arguments.contains("-UI_TEST_RESET_DEFAULTS") {
            state = .signedOut
            return
        }

        do {
            let user = try await SupabaseService.shared.client.auth.session.user
            state = .signedIn(userId: user.id, email: user.email)
        } catch {
            state = .signedOut
        }

        for await (_, session) in SupabaseService.shared.client.auth.authStateChanges {
            guard !Task.isCancelled else { return }
            if let user = session?.user {
                state = .signedIn(userId: user.id, email: user.email)
            } else {
                state = .signedOut
            }
        }
    }

    private enum Mode: Equatable {
        case live
        case preview
    }
}
