import SwiftUI

@main
struct MemoryMapApp: App {
    @StateObject private var prefs = UserPreferences()

    private let evidenceMode: MemoryComposerEvidenceMode = {
        guard
            let rawValue = ProcessInfo.processInfo.environment["MEMORYMAP_EVIDENCE_MODE"],
            let mode = MemoryComposerEvidenceMode(rawValue: rawValue)
        else {
            return .none
        }

        return mode
    }()

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
