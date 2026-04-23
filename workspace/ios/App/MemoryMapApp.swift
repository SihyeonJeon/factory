import SwiftUI

@main
struct MemoryMapApp: App {
    @StateObject private var prefs: UserPreferences

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
        _prefs = StateObject(wrappedValue: UserPreferences(forceHasSeenOnboarding: Self.shouldSkipOnboardingForUITests))
    }

    private static var shouldSkipOnboardingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UI_TEST_SKIP_ONBOARDING")
            || ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1"
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if prefs.hasSeenOnboarding {
                    RootTabView(evidenceMode: evidenceMode)
                } else {
                    OnboardingView {
                        prefs.hasSeenOnboarding = true
                    }
                }
            }
        }
    }
}
