import SwiftUI

enum HomeDeepLinkAction: Equatable {
    case rewind
}

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
    @EnvironmentObject private var deepLinkStore: DeepLinkStore
    @EnvironmentObject private var memoryStore: MemoryStore
    @EnvironmentObject private var offlineQueue: OfflineQueue

    private let evidenceMode: MemoryComposerEvidenceMode

    @State private var selectedTab: ShellTab = .map
    @State private var sheetSnap: BottomSheetSnap
    @State private var isPresentingComposer = false
    @State private var isPresentingGroupOnboarding = false
    @State private var showingGroupPicker = false
    @State private var showingCategoryEditor = false
    @State private var didPresentEvidenceComposer = false
    @State private var groupSwitchResetToken = 0
    @State private var pendingAutoselectMemoryId: UUID?
    @State private var pendingMemoryDetailId: UUID?
    @State private var pendingCalendarEventId: UUID?
    @State private var pendingHomeDeepLinkAction: HomeDeepLinkAction?
    @State private var pendingComposerLaunchRoute: ComposerLaunchRoute?
    @StateObject private var categoryStore: CategoryStore

    init(
        evidenceMode: MemoryComposerEvidenceMode = .none,
        initialSheetSnap: BottomSheetSnap = Self.initialSheetSnap()
    ) {
        self.evidenceMode = evidenceMode
        self._sheetSnap = State(initialValue: initialSheetSnap)
        self._categoryStore = StateObject(wrappedValue: CategoryStore.shared)
    }

    var body: some View {
        GeometryReader { proxy in
            let sheetTop = MemoryMapHomeLayout.sheetTopY(
                screenHeight: proxy.size.height,
                safeBottom: proxy.safeAreaInsets.bottom,
                snap: sheetSnap
            )

            ZStack(alignment: .bottom) {
                currentScreen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if selectedTab == .map {
                    ComposeFAB {
                        pendingComposerLaunchRoute = nil
                        isPresentingComposer = true
                    }
                    .opacity(sheetSnap == .expanded ? 0 : 1)
                    .allowsHitTesting(sheetSnap != .expanded)
                    .animation(.easeInOut(duration: 0.22), value: sheetSnap)
                    .position(
                        x: proxy.size.width - MemoryMapHomeLayout.fabRight - 28,
                        y: sheetTop - MemoryMapHomeLayout.fabBottomGap - 28
                    )
                    .zIndex(70)
                }

                UnfadingTabBar(
                    selected: $selectedTab,
                    showsMapBadge: memoryStore.pendingIncomingMemoryId != nil,
                    onTabSelected: handleTabSelection
                )
                    .zIndex(120)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: UnfadingTheme.Spacing.xs) {
                    if offlineQueue.pendingCount > 0 {
                        offlineQueueBanner
                    }

                    if let pendingMemoryId = memoryStore.pendingIncomingMemoryId {
                        Button {
                            openIncomingMemory(id: pendingMemoryId)
                        } label: {
                            UnfadingToast(message: UnfadingLocalized.Home.incomingMemoryToast)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(UnfadingLocalized.Home.incomingMemoryToast)
                        .accessibilityHint(UnfadingLocalized.Accessibility.mapTabHint)
                        .accessibilityIdentifier("incoming-memory-toast")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, UnfadingTheme.Spacing.lg)
                .padding(.bottom, UnfadingTabBar.height + UnfadingTheme.Spacing.sm)
            }
            .overlay {
                GroupPickerOverlay(
                    isPresented: $showingGroupPicker,
                    onCreateGroup: { isPresentingGroupOnboarding = true },
                    onGroupChanged: {
                        sheetSnap = .default_
                        groupSwitchResetToken += 1
                    }
                )
                .environmentObject(categoryStore)

                CategoryEditorOverlay(isPresented: $showingCategoryEditor)
                    .environmentObject(categoryStore)
            }
        }
        .background(UnfadingTheme.Color.bg)
        .environmentObject(categoryStore)
        .fullScreenCover(
            isPresented: $isPresentingComposer,
            onDismiss: { pendingComposerLaunchRoute = nil }
        ) {
            MemoryComposerSheet(
                initialLocationPermissionState: .denied,
                evidenceMode: evidenceMode,
                sharedPhotoReference: pendingComposerLaunchRoute?.photoReference
            )
        }
        .sheet(isPresented: $isPresentingGroupOnboarding) {
            GroupOnboardingView()
        }
        .onChange(of: showingGroupPicker) { _, isShowing in
            if isShowing { showingCategoryEditor = false }
        }
        .onChange(of: showingCategoryEditor) { _, isShowing in
            if isShowing { showingGroupPicker = false }
        }
        .onAppear {
            consumePendingDeepLinkIfNeeded()
            guard evidenceMode != .none, didPresentEvidenceComposer == false, isPresentingComposer == false else { return }
            didPresentEvidenceComposer = true
            isPresentingComposer = true
        }
        .onChange(of: deepLinkStore.pendingDeepLink) { _, target in
            guard target != nil else { return }
            consumePendingDeepLinkIfNeeded()
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .map:
            MemoryMapHomeView(
                sheetSnap: $sheetSnap,
                autoSelectMemoryId: $pendingAutoselectMemoryId,
                pendingMemoryDetailId: $pendingMemoryDetailId,
                pendingHomeDeepLinkAction: $pendingHomeDeepLinkAction,
                evidenceMode: evidenceMode,
                groupSwitchResetToken: groupSwitchResetToken,
                onSwitchGroup: { showingGroupPicker = true },
                onEditCategories: { showingCategoryEditor = true }
            )
        case .calendar:
            CalendarView(pendingEventID: $pendingCalendarEventId)
        case .settings:
            SettingsView()
        }
    }

    private static func initialSheetSnap() -> BottomSheetSnap {
        for arg in ProcessInfo.processInfo.arguments {
            if arg.hasPrefix("-UI_TEST_SHEET_SNAP=") {
                let value = String(arg.dropFirst("-UI_TEST_SHEET_SNAP=".count))
                switch value {
                case "collapsed": return .collapsed
                case "expanded": return .expanded
                default: return .default_
                }
            }
        }
        return .default_
    }

    private func handleTabSelection(_ tab: ShellTab) {
        if tab == .map, let pendingMemoryId = memoryStore.pendingIncomingMemoryId {
            openIncomingMemory(id: pendingMemoryId)
            return
        }

        selectedTab = tab
    }

    private func openIncomingMemory(id: UUID) {
        selectedTab = .map
        pendingAutoselectMemoryId = id
        memoryStore.clearPendingIncomingMemory()
    }

    private var offlineQueueBanner: some View {
        Text(UnfadingLocalized.Home.offlineQueueBanner(offlineQueue.pendingCount))
            .font(UnfadingTheme.Font.captionSemibold())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.md)
            .padding(.vertical, UnfadingTheme.Spacing.sm)
            .background(
                UnfadingTheme.Color.sheet.opacity(0.96),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
            }
            .shadow(style: UnfadingTheme.Shadow.card)
            .accessibilityIdentifier("offline-queue-banner")
    }

    private func consumePendingDeepLinkIfNeeded() {
        guard let deepLink = deepLinkStore.pendingDeepLink else { return }

        switch deepLink {
        case let .memory(memoryID):
            selectedTab = .map
            pendingAutoselectMemoryId = memoryID
            pendingMemoryDetailId = memoryID
        case let .event(eventID):
            selectedTab = .calendar
            pendingCalendarEventId = eventID
        case let .composer(preSelectedPhotoID):
            selectedTab = .map
            pendingComposerLaunchRoute = ComposerLaunchRoute(preSelectedPhotoID: preSelectedPhotoID)
            isPresentingComposer = true
        case .rewind:
            selectedTab = .map
            pendingHomeDeepLinkAction = .rewind
        }

        deepLinkStore.pendingDeepLink = nil
    }
}

struct UnfadingTabBar: View {
    static let height: CGFloat = 83

    @Binding var selected: ShellTab
    let showsMapBadge: Bool
    let onTabSelected: (ShellTab) -> Void

    init(
        selected: Binding<ShellTab>,
        showsMapBadge: Bool = false,
        onTabSelected: @escaping (ShellTab) -> Void = { _ in }
    ) {
        self._selected = selected
        self.showsMapBadge = showsMapBadge
        self.onTabSelected = onTabSelected
    }

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
            onTabSelected(tab)
        } label: {
            VStack(spacing: UnfadingTheme.Spacing.xxs) {
                Image(systemName: tab.systemImage)
                    .imageScale(.medium)
                    .overlay(alignment: .topTrailing) {
                        if tab == .map, showsMapBadge {
                            Circle()
                                .fill(UnfadingTheme.Color.primary)
                                .frame(width: 10, height: 10)
                                .overlay {
                                    Circle()
                                        .stroke(UnfadingTheme.Color.sheet, lineWidth: 1.5)
                                }
                                .offset(x: 6, y: -3)
                                .accessibilityHidden(true)
                        }
                    }
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
        .accessibilityValue(tab == .map && showsMapBadge ? UnfadingLocalized.Home.incomingMemoryBadge : "")
        .accessibilityIdentifier(tab.identifier)
    }
}

#Preview {
    UnfadingTabShell()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(UserPreferences())
        .environmentObject(GroupStore.preview())
        .environmentObject(OfflineQueue())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
        .environmentObject(SubscriptionStore())
}
