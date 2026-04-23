import SwiftUI

@main
struct MemoryMapApp: App {
    @StateObject private var prefs: UserPreferences
    @StateObject private var authStore: AuthStore
    @StateObject private var groupStore: GroupStore

    private let evidenceMode: MemoryComposerEvidenceMode = {
        guard
            let rawValue = ProcessInfo.processInfo.environment["MEMORYMAP_EVIDENCE_MODE"],
            let mode = MemoryComposerEvidenceMode(rawValue: rawValue)
        else {
            return .none
        }

        return mode
    }()

    init() {
        if ProcessInfo.processInfo.arguments.contains("-UI_TEST_RESET_DEFAULTS"),
           let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        _prefs = StateObject(wrappedValue: UserPreferences(forceHasSeenOnboarding: Self.shouldSkipOnboardingForUITests))
        _authStore = StateObject(wrappedValue: AuthStore())
        _groupStore = StateObject(wrappedValue: Self.makeGroupStore())
    }

    private static var shouldSkipOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
    }

    private static var isUITestGroupStubEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_GROUP_STUB")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST_GROUP_STUB"] == "1"
    }

    @MainActor
    private static func makeGroupStore() -> GroupStore {
        #if DEBUG
        let store = AuthStore.isUITestAuthStubEnabled ? GroupStore(repo: PreviewGroupRepository()) : GroupStore()
        if isUITestGroupStubEnabled {
            store.applyUITestStub()
        }
        return store
        #else
        return GroupStore()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.state == .unknown {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if case .signedIn = authStore.state {
                    if prefs.hasSeenOnboarding {
                        if groupStore.state == .loading || groupStore.state == .idle {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .task {
                                    await groupStore.bootstrap()
                                }
                        } else if groupStore.groups.isEmpty {
                            GroupOnboardingView()
                                .environmentObject(groupStore)
                        } else {
                            RootTabView(evidenceMode: evidenceMode)
                                .environmentObject(authStore)
                                .environmentObject(groupStore)
                        }
                    } else {
                        OnboardingView {
                            prefs.hasSeenOnboarding = true
                        }
                    }
                } else {
                    AuthLandingView()
                        .environmentObject(authStore)
                }
            }
            .onReceive(authStore.$state) { state in
                guard case .signedIn = state else { return }
                guard !Self.isUITestGroupStubEnabled else { return }
                Task { await groupStore.bootstrap() }
            }
        }
    }
}
