import SwiftUI

/// Backward-compatible root wrapper. R27 moves tab ownership into
/// `UnfadingTabShell` so the tab bar, FAB, and modal presentation share one
/// root z-layer stack.
struct RootTabView: View {
    private let evidenceMode: MemoryComposerEvidenceMode
    private let initialSheetSnap: BottomSheetSnap

    init(
        evidenceMode: MemoryComposerEvidenceMode = .none,
        initialSheetSnap: BottomSheetSnap = .default_
    ) {
        self.evidenceMode = evidenceMode
        self.initialSheetSnap = initialSheetSnap
    }

    var body: some View {
        UnfadingTabShell(
            evidenceMode: evidenceMode,
            initialSheetSnap: initialSheetSnap
        )
    }
}

#Preview {
    RootTabView()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(DeepLinkStore())
        .environmentObject(UserPreferences())
        .environmentObject(GroupStore.preview())
        .environmentObject(OfflineQueue())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
