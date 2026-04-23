import SwiftUI

/// Root tab controller. R3 `round_navigation_r1` raised tab count 3 → 5 per the
/// deepsight redesign: 지도 / 캘린더 / 추억(compose) / 리와인드 / 설정. The
/// compose tab is a pseudo-destination — selecting it presents the composer as
/// a fullScreenCover and restores the previous tab on dismiss. Groups were
/// demoted from a top-level tab to a row inside Settings this round; future
/// rounds surface Group Hub via a Map top-left chip.
struct RootTabView: View {
    enum Tab: Hashable, CaseIterable {
        case map
        case calendar
        case compose
        case rewind
        case settings

        /// Canonical order from the R3 plan. Tests assert against this rather
        /// than re-declaring the expected order locally.
        static let rootOrder: [Tab] = [.map, .calendar, .compose, .rewind, .settings]
    }

    private let evidenceMode: MemoryComposerEvidenceMode

    @State private var selectedTab: Tab = .map
    @State private var previousTab: Tab = .map
    @State private var isPresentingComposer: Bool = false

    init(evidenceMode: MemoryComposerEvidenceMode = .none) {
        self.evidenceMode = evidenceMode
    }

    var body: some View {
        TabView(selection: bindingForSelection) {
            MemoryMapHomeView(evidenceMode: evidenceMode)
                .tabItem {
                    Label(UnfadingLocalized.Tab.map, systemImage: "map")
                }
                .tag(Tab.map)
                .accessibilityLabel(UnfadingLocalized.Accessibility.mapTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.mapTabHint)

            CalendarView()
                .tabItem {
                    Label(UnfadingLocalized.Tab.calendar, systemImage: "calendar")
                }
                .tag(Tab.calendar)
                .accessibilityLabel(UnfadingLocalized.Accessibility.calendarTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.calendarTabHint)

            // Placeholder view for the compose tab — TabView requires a destination per tag.
            // Actual behavior: selecting this tab presents MemoryComposerSheet via
            // `bindingForSelection` below; this view should never be seen in practice.
            ComposeTabPlaceholder()
                .tabItem {
                    Label(UnfadingLocalized.Tab.compose, systemImage: "plus.circle.fill")
                }
                .tag(Tab.compose)
                .accessibilityLabel(UnfadingLocalized.Accessibility.composeTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.composeTabHint)

            RewindFeedView()
                .tabItem {
                    Label(UnfadingLocalized.Tab.rewind, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .tag(Tab.rewind)
                .accessibilityLabel(UnfadingLocalized.Accessibility.rewindTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.rewindTabHint)

            SettingsView()
                .tabItem {
                    Label(UnfadingLocalized.Tab.settings, systemImage: "gearshape")
                }
                .tag(Tab.settings)
                .accessibilityLabel(UnfadingLocalized.Accessibility.settingsTabLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.settingsTabHint)
        }
        .tint(UnfadingTheme.Color.primary)
        .fullScreenCover(isPresented: $isPresentingComposer, onDismiss: {
            // Restore the prior tab after composer dismissal
            selectedTab = previousTab
        }) {
            MemoryComposerSheet(
                initialLocationPermissionState: .denied,
                evidenceMode: evidenceMode
            )
        }
    }

    /// Intercept selection: if the user taps the compose tab, remember the previous
    /// tab, snap selection back to the previous tab, and present the composer full-
    /// screen. This avoids the TabView leaving the user "stranded" on the placeholder.
    private var bindingForSelection: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == .compose {
                    previousTab = selectedTab
                    isPresentingComposer = true
                    // Do NOT advance selectedTab; keep it on previousTab so the UI
                    // doesn't flicker the placeholder while the cover animates up.
                } else {
                    selectedTab = newValue
                }
            }
        )
    }
}

/// Placeholder destination for the compose tab. See note in `RootTabView.body`.
/// Intentionally minimal; the fullScreenCover covers the tab before SwiftUI can
/// render this view.
private struct ComposeTabPlaceholder: View {
    var body: some View {
        Color.clear.accessibilityHidden(true)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(UserPreferences())
        .environmentObject(GroupStore.preview())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
