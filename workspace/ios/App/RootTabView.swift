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
                    Label("Map", systemImage: "map")
                }
                .accessibilityLabel("Map tab")
                .accessibilityHint("Browse memory pins and place history on the map.")

            RewindFeedView()
                .tabItem {
                    Label("Rewind", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .accessibilityLabel("Rewind tab")
                .accessibilityHint("Review rewind moments and reminder settings.")

            GroupHubView()
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
                .accessibilityLabel("Groups tab")
                .accessibilityHint("Create groups, join groups, and manage invites.")
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    RootTabView()
}
