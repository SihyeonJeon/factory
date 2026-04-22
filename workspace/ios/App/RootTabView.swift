import SwiftUI

struct RootTabView: View {
    private let evidenceMode: MemoryComposerEvidenceMode

    init(evidenceMode: MemoryComposerEvidenceMode = .none) {
        self.evidenceMode = evidenceMode
    }

    var body: some View {
        TabView {
            MemoryMapHomeView(evidenceMode: evidenceMode)
                .tabItem {
                    Label(UnfadingLocalized.Tab.map, systemImage: "map")
                }
                .accessibilityLabel(UnfadingLocalized.Accessibility.mapTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.mapTabHint)

            RewindFeedView()
                .tabItem {
                    Label(UnfadingLocalized.Tab.rewind, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .accessibilityLabel(UnfadingLocalized.Accessibility.rewindTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.rewindTabHint)

            GroupHubView()
                .tabItem {
                    Label(UnfadingLocalized.Tab.groups, systemImage: "person.3")
                }
                .accessibilityLabel(UnfadingLocalized.Accessibility.groupsTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.groupsTabHint)
        }
        .tint(UnfadingTheme.Color.primary)
    }
}

#Preview {
    RootTabView()
}
