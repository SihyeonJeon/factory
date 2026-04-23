import SwiftUI

/// Backward-compatible root wrapper. R27 moves tab ownership into
/// `UnfadingTabShell` so the tab bar, FAB, and modal presentation share one
/// root z-layer stack.
struct RootTabView: View {
    private let evidenceMode: MemoryComposerEvidenceMode

    init(evidenceMode: MemoryComposerEvidenceMode = .none) {
        self.evidenceMode = evidenceMode
    }

    var body: some View {
        UnfadingTabShell(evidenceMode: evidenceMode)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(UserPreferences())
        .environmentObject(GroupStore.preview())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
