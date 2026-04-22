import SwiftUI

@main
struct MemoryMapApp: App {
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
            RootTabView(evidenceMode: evidenceMode)
        }
    }
}
