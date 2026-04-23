import SwiftUI

@main
struct MemoryMapApp: App {
    @StateObject private var prefs: UserPreferences
    @StateObject private var authStore = AuthStore()

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
    }

    private static var shouldSkipOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.state == .unknown {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if case .signedIn = authStore.state {
                    if prefs.hasSeenOnboarding {
                        RootTabView(evidenceMode: evidenceMode)
                            .environmentObject(authStore)
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
        }
    }
}
