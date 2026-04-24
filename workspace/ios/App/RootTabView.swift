import SwiftUI

/// Backward-compatible root wrapper. R27 moves tab ownership into
/// `UnfadingTabShell` so the tab bar, FAB, and modal presentation share one
/// root z-layer stack.
struct RootTabView: View {
    private let evidenceMode: MemoryComposerEvidenceMode
    private let initialSheetSnap: BottomSheetSnap
    @Binding private var composerLaunchRoute: ComposerLaunchRoute?

    init(
        evidenceMode: MemoryComposerEvidenceMode = .none,
        initialSheetSnap: BottomSheetSnap = .default_,
        composerLaunchRoute: Binding<ComposerLaunchRoute?> = .constant(nil)
    ) {
        self.evidenceMode = evidenceMode
        self.initialSheetSnap = initialSheetSnap
        self._composerLaunchRoute = composerLaunchRoute
    }

    var body: some View {
        UnfadingTabShell(
            evidenceMode: evidenceMode,
            initialSheetSnap: initialSheetSnap,
            composerLaunchRoute: $composerLaunchRoute
        )
    }
}

#Preview {
    RootTabView()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(UserPreferences())
        .environmentObject(GroupStore.preview())
        .environmentObject(OfflineQueue())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
