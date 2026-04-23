import SwiftUI

enum ShellTab: String, CaseIterable {
    case map
    case calendar
    case settings

    var systemImage: String {
        switch self {
        case .map: return "map"
        case .calendar: return "calendar"
        case .settings: return "gearshape"
        }
    }

    var label: String {
        switch self {
        case .map: return UnfadingLocalized.Tab.map
        case .calendar: return UnfadingLocalized.Tab.calendar
        case .settings: return UnfadingLocalized.Tab.settings
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .map: return UnfadingLocalized.Accessibility.mapTabLabel
        case .calendar: return UnfadingLocalized.Accessibility.calendarTabLabel
        case .settings: return UnfadingLocalized.Accessibility.settingsTabLabel
        }
    }

    var accessibilityHint: String {
        switch self {
        case .map: return UnfadingLocalized.Accessibility.mapTabHint
        case .calendar: return UnfadingLocalized.Accessibility.calendarTabHint
        case .settings: return UnfadingLocalized.Accessibility.settingsTabHint
        }
    }

    var identifier: String { "tab-\(rawValue)" }
}

struct UnfadingTabShell: View {
    private let evidenceMode: MemoryComposerEvidenceMode

    @State private var selectedTab: ShellTab = .map
    @State private var sheetExpanded = false
    @State private var isPresentingComposer = false
    @State private var didPresentEvidenceComposer = false

    init(evidenceMode: MemoryComposerEvidenceMode = .none) {
        self.evidenceMode = evidenceMode
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if selectedTab == .map && !sheetExpanded {
                ComposeFAB {
                    isPresentingComposer = true
                }
                .padding(.trailing, UnfadingTheme.Spacing.md2)
                .padding(.bottom, UnfadingTabBar.height + UnfadingTheme.Spacing.md2)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .zIndex(70)
            }

            UnfadingTabBar(selected: $selectedTab)
                .zIndex(120)
        }
        .background(UnfadingTheme.Color.bg)
        .fullScreenCover(isPresented: $isPresentingComposer) {
            MemoryComposerSheet(
                initialLocationPermissionState: .denied,
                evidenceMode: evidenceMode
            )
        }
        .onAppear {
            guard evidenceMode != .none, didPresentEvidenceComposer == false else { return }
            didPresentEvidenceComposer = true
            isPresentingComposer = true
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .map:
            MemoryMapHomeView(evidenceMode: evidenceMode)
        case .calendar:
            CalendarView()
        case .settings:
            SettingsView()
        }
    }
}

struct UnfadingTabBar: View {
    static let height: CGFloat = 83

    @Binding var selected: ShellTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ShellTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .frame(height: Self.height, alignment: .top)
        .padding(.top, UnfadingTheme.Spacing.xs)
        .background(UnfadingTheme.Color.sheet.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(UnfadingTheme.Color.divider)
                .frame(height: 0.5)
        }
        .shadow(style: UnfadingTheme.Shadow.tabBarBorder)
    }

    private func tabButton(_ tab: ShellTab) -> some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: UnfadingTheme.Spacing.xxs) {
                Image(systemName: tab.systemImage)
                    .imageScale(.medium)
                Text(tab.label)
                    .font(UnfadingTheme.Font.tag(11))
            }
            .foregroundStyle(selected == tab ? UnfadingTheme.Color.primary : UnfadingTheme.Color.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityIdentifier(tab.identifier)
    }
}

#Preview {
    UnfadingTabShell()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(UserPreferences())
        .environmentObject(GroupStore.preview())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
        .environmentObject(SubscriptionStore())
}
