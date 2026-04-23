import MapKit
import SwiftUI
import UIKit

/// Main map surface redesigned per deepsight spec in R4 `round_map_redesign_r1`:
/// persistent 3-snap bottom sheet, filter chip row, FAB (coral), top-left group
/// chip, top-right search. Pin taps update `MemorySelectionState` which drives
/// both summary content and sheet snap.
struct MemoryMapHomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var groupStore: GroupStore
    @EnvironmentObject private var categoryStore: CategoryStore
    @EnvironmentObject private var memoryStore: MemoryStore
    private let evidenceMode: MemoryComposerEvidenceMode
    private let groupSwitchResetToken: Int
    private let onSwitchGroup: () -> Void
    private let onEditCategories: () -> Void
    @Binding private var autoSelectMemoryId: UUID?
    @Binding private var sheetSnap: BottomSheetSnap
    @StateObject private var locationPermissionStore = LocationPermissionStore()
    @StateObject private var selection = MemorySelectionState()
    @State private var activeCategoryId = CategoryStore.allCategoryId
    @State private var activeSheetTab: SheetTab = .curation
    @State private var showingRewind = false
    @State private var detailMemory: DBMemory?
    @State private var measuredSheetHeight: CGFloat = 0
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    init(
        sheetSnap: Binding<BottomSheetSnap> = .constant(.default_),
        autoSelectMemoryId: Binding<UUID?> = .constant(nil),
        evidenceMode: MemoryComposerEvidenceMode = .none,
        groupSwitchResetToken: Int = 0,
        onSwitchGroup: @escaping () -> Void = {},
        onEditCategories: @escaping () -> Void = {}
    ) {
        self._sheetSnap = sheetSnap
        self._autoSelectMemoryId = autoSelectMemoryId
        self.evidenceMode = evidenceMode
        self.groupSwitchResetToken = groupSwitchResetToken
        self.onSwitchGroup = onSwitchGroup
        self.onEditCategories = onEditCategories
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let screenWidth = proxy.size.width
                let screenHeight = proxy.size.height
                let safeBottom = proxy.safeAreaInsets.bottom
                let sheetTop = MemoryMapHomeLayout.sheetTopY(
                    screenHeight: screenHeight,
                    safeBottom: safeBottom,
                    snap: sheetSnap
                )

                ZStack(alignment: .topLeading) {
                    mapLayer
                        .ignoresSafeArea(edges: .top)
                        .zIndex(10)

                    topChrome
                        .frame(
                            width: screenWidth - (MemoryMapHomeLayout.horizontalInset * 2),
                            height: MemoryMapHomeLayout.topChromeHeight
                        )
                        .position(
                            x: screenWidth / 2,
                            y: MemoryMapHomeLayout.topChromeTop + (MemoryMapHomeLayout.topChromeHeight / 2)
                        )
                        .chromeVisibility(sheetSnap)
                        .zIndex(30)

                    filterRow
                        .frame(width: screenWidth, height: MemoryMapHomeLayout.filterChipHeight)
                        .position(
                            x: screenWidth / 2,
                            y: MemoryMapHomeLayout.filterChipTop + (MemoryMapHomeLayout.filterChipHeight / 2)
                        )
                        .chromeVisibility(sheetSnap)
                        .zIndex(28)

                    mapControls
                        .frame(width: MemoryMapHomeLayout.mapControlsSize, height: MemoryMapHomeLayout.mapControlsStackHeight)
                        .position(
                            x: screenWidth - MemoryMapHomeLayout.mapControlsRight - (MemoryMapHomeLayout.mapControlsSize / 2),
                            y: sheetTop - MemoryMapHomeLayout.mapControlsBottomGap - (MemoryMapHomeLayout.mapControlsStackHeight / 2)
                        )
                        .chromeVisibility(sheetSnap)
                        .zIndex(26)

                    UnfadingBottomSheet(
                        snap: $sheetSnap,
                        measuredHeight: $measuredSheetHeight,
                        tabBarHeight: UnfadingTabBar.height,
                        collapsedSummary: {
                            CollapsedSummary(mode: groupStore.mode, count: memoryStore.memories.count)
                        },
                        expandedHeader: { collapseToDefault in
                            SheetExpandedHeader(
                                groupName: groupStore.activeGroup?.name ?? UnfadingLocalized.Home.groupChipPlaceholder,
                                memberInitials: headerInitials,
                                onBack: collapseToDefault
                            )
                        }
                    ) {
                        if let selectedCluster = selection.selectedCluster(from: memoryPinClusters) {
                            SheetFilteredContent(cluster: selectedCluster) {
                                selection.clearSelection()
                                sheetSnap = selection.sheetSnap
                            }
                        } else {
                            HomeSheetContent(
                                selectedTab: $activeSheetTab,
                                mode: groupStore.mode,
                                onRewindTap: showRewindFromCuration
                            )
                        }
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .zIndex(50)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingRewind) {
                RewindFeedView {
                    showingRewind = false
                    sheetSnap = .default_
                }
            }
            .navigationDestination(item: $detailMemory) { memory in
                MemoryDetailView(
                    memory: memory,
                    eventMemories: relatedMemories(for: memory),
                    participants: groupStore.memberProfiles,
                    mode: groupStore.mode
                )
            }
            .confirmationDialog(
                locationPermissionStore.recoveryPrompt?.title ?? "",
                isPresented: recoveryPromptIsPresented,
                titleVisibility: .visible
            ) {
                if let prompt = locationPermissionStore.recoveryPrompt {
                    ForEach(prompt.actions) { action in
                        Button(action.title) { handleRecoveryAction(action) }
                    }
                }
                Button(UnfadingLocalized.Common.cancel, role: .cancel) {
                    locationPermissionStore.dismissRecoveryPrompt()
                }
            } message: {
                if let prompt = locationPermissionStore.recoveryPrompt {
                    Text(prompt.message)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { locationPermissionStore.refresh() }
            }
            .onChange(of: categoryStore.categories) { _, categories in
                guard activeCategoryId == CategoryStore.allCategoryId || categories.contains(where: { $0.id == activeCategoryId }) else {
                    activeCategoryId = CategoryStore.allCategoryId
                    return
                }
            }
            .onChange(of: groupSwitchResetToken) { _, _ in
                selection.clearSelection()
                activeCategoryId = CategoryStore.allCategoryId
                activeSheetTab = .curation
                sheetSnap = .default_
            }
            .onChange(of: autoSelectMemoryId) { _, _ in
                applyAutoSelectionIfNeeded()
            }
            .onChange(of: memoryStore.memories) { _, _ in
                applyAutoSelectionIfNeeded()
            }
            .onAppear {
                applyAutoSelectionIfNeeded()
            }
        }
    }

    // MARK: Layers

    private var mapLayer: some View {
        Map(position: $cameraPosition, selection: .constant(nil as UUID?)) {
            ForEach(memoryPinClusters) { cluster in
                Annotation(cluster.representativeMemory.title, coordinate: cluster.coordinate) {
                    Button {
                        selection.select(cluster: cluster)
                        sheetSnap = selection.sheetSnap
                    } label: {
                        if cluster.count > 1 {
                            ClusterMarker(
                                cluster: cluster,
                                isSelected: cluster.contains(memoryID: selection.selectedPinID),
                                isDimmed: selection.selectedPinID != nil && !cluster.contains(memoryID: selection.selectedPinID)
                            )
                        } else {
                            MemoryPinMarker(
                                memory: cluster.representativeMemory,
                                isSelected: cluster.contains(memoryID: selection.selectedPinID),
                                isDimmed: selection.selectedPinID != nil && !cluster.contains(memoryID: selection.selectedPinID)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(UnfadingLocalized.Accessibility.mapPinLabel(title: cluster.representativeMemory.title))
                    .accessibilityHint(UnfadingLocalized.Accessibility.mapPinHint)
                    .accessibilityIdentifier("memory-pin-\(cluster.representativeMemory.id.uuidString)")
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    private var topChrome: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            Button {
                onSwitchGroup()
            } label: {
                HStack(spacing: UnfadingTheme.Spacing.xs) {
                    avatarStack
                    VStack(alignment: .leading, spacing: 2) {
                        Text(groupName)
                            .font(UnfadingTheme.Font.sectionTitle(15))
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            .lineLimit(1)
                        Text(groupSubtitle)
                            .font(UnfadingTheme.Font.tag(11))
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(groupName)
            .accessibilityHint(UnfadingLocalized.Home.groupChipHint)
            .accessibilityIdentifier("home-top-chrome-group-button")

            Button {
                // Search stub — full implementation in a future round.
            } label: {
                Image(systemName: "magnifyingglass")
                    .imageScale(.medium)
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(UnfadingTheme.Color.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Home.searchLabel)
            .accessibilityHint(UnfadingLocalized.Home.searchHint)
        }
        .padding(.horizontal, UnfadingTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: MemoryMapHomeLayout.topChromeRadius, style: .continuous)
                .fill(UnfadingTheme.Color.sheet.opacity(0.94))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MemoryMapHomeLayout.topChromeRadius, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: MemoryMapHomeLayout.topChromeRadius, style: .continuous)
                .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
        }
        .shadow(style: UnfadingTheme.Shadow.card)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-top-chrome")
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UnfadingTheme.Spacing.sm) {
                UnfadingFilterChip(
                    title: UnfadingLocalized.Home.filterAll,
                    systemImage: "sparkles",
                    isSelected: activeCategoryId == CategoryStore.allCategoryId
                ) {
                    activeCategoryId = CategoryStore.allCategoryId
                }

                ForEach(categoryStore.categories) { category in
                    UnfadingFilterChip(
                        title: category.name,
                        systemImage: category.icon,
                        isSelected: activeCategoryId == category.id
                    ) {
                        activeCategoryId = activeCategoryId == category.id ? CategoryStore.allCategoryId : category.id
                    }
                }

                Button {
                    onEditCategories()
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.small)
                        .foregroundStyle(UnfadingTheme.Color.primary.opacity(0.66))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle()
                                .stroke(
                                    UnfadingTheme.Color.primary.opacity(0.66),
                                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(UnfadingLocalized.Categories.addCategory)
                .accessibilityIdentifier("home-filter-add-category")
            }
            .padding(.horizontal, UnfadingTheme.Spacing.md)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(UnfadingLocalized.Accessibility.filterRowLabel)
        .accessibilityHint(UnfadingLocalized.Accessibility.filterRowHint)
        .accessibilityIdentifier("home-filter-chip-bar")
    }

    private var mapControls: some View {
        VStack(spacing: MemoryMapHomeLayout.mapControlsSpacing) {
            mapControlButton(systemName: "location.fill", accessibilityLabel: UnfadingLocalized.Accessibility.showCurrentLocationLabel) {
                _ = locationPermissionStore.handleCurrentLocationTap()
            }

            mapControlButton(systemName: "location.north.line.fill", accessibilityLabel: UnfadingLocalized.Accessibility.resetMapOrientationLabel) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                    )
                )
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.25) : .interpolatingSpring(stiffness: 260, damping: 32), value: measuredSheetHeight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-map-controls")
    }

    private var avatarStack: some View {
        let initials = Array(headerInitials.prefix(3))
        return ZStack(alignment: .leading) {
            ForEach(Array(initials.enumerated()), id: \.offset) { index, initial in
                Text(initial)
                    .font(UnfadingTheme.Font.tag(11))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(width: 28, height: 28)
                    .background(UnfadingTheme.Color.memberPalette[index % UnfadingTheme.Color.memberPalette.count], in: Circle())
                    .overlay(Circle().stroke(UnfadingTheme.Color.sheet, lineWidth: 1.5))
                    .offset(x: CGFloat(index) * 18)
            }

            if groupStore.mode == .couple, initials.count >= 2 {
                Image(systemName: "heart.fill")
                    .imageScale(.small)
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(width: 16, height: 16)
                    .background(UnfadingTheme.Color.primary, in: Circle())
                    .offset(x: 20, y: 8)
            }
        }
        .frame(width: max(28, 28 + CGFloat(max(0, initials.count - 1)) * 18), height: 34, alignment: .leading)
    }

    private var groupName: String {
        groupStore.activeGroup?.name ?? SampleGroup.sampleCouple.name
    }

    private var groupSubtitle: String {
        UnfadingLocalized.Home.groupSubtitle(
            mode: groupStore.mode,
            memberCount: memberCount,
            days: daysTogether
        )
    }

    private var memberCount: Int {
        let count = groupStore.memberProfiles.count
        return count > 0 ? count : SampleGroup.sampleCouple.members.count
    }

    private var daysTogether: Int {
        let start = groupStore.activeGroup?.createdAt ?? Calendar.current.date(byAdding: .day, value: -99, to: Date()) ?? Date()
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(days + 1, 1)
    }

    private var headerInitials: [String] {
        let profiles = groupStore.memberProfiles
        if profiles.isEmpty {
            return SampleGroup.sampleCouple.members.map(\.initial)
        }

        return profiles.prefix(3).map { profile in
            let name = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            return String((name?.first ?? "?"))
        }
    }

    private var memoryPinClusters: [MemoryPinCluster] {
        memoryStore.memories.clusteredByCoordinateRadius()
    }

    private func mapControlButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .imageScale(.medium)
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .frame(width: MemoryMapHomeLayout.mapControlsSize, height: MemoryMapHomeLayout.mapControlsSize)
                .background {
                    Circle()
                        .fill(UnfadingTheme.Color.sheet.opacity(0.94))
                        .background(.ultraThinMaterial, in: Circle())
                }
                .shadow(color: UnfadingTheme.Color.textPrimary.opacity(0.10), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(MapControlButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Helpers

    // vibe-limit-checked: 8 a11y/hints/reduce-motion, 1 parent owns navigation, 12 navigation state transition testable
    private var recoveryPromptIsPresented: Binding<Bool> {
        Binding(
            get: { locationPermissionStore.recoveryPrompt != nil },
            set: { isPresented in
                if !isPresented { locationPermissionStore.dismissRecoveryPrompt() }
            }
        )
    }

    private func handleRecoveryAction(_ action: LocationPermissionRecoveryAction) {
        switch locationPermissionStore.handleRecoveryAction(action) {
        case .openSettings:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        case .continueWithoutLocation:
            break
        }
    }

    // vibe-limit-checked: 8 a11y detail handoff remains labeled, 1 parent owns navigation, 12 navigation state transition testable
    private func openDetail() {
        detailMemory = selection.selectedMemory(from: memoryStore.memories) ?? memoryStore.memories.first
    }

    private func relatedMemories(for memory: DBMemory) -> [DBMemory] {
        let scoped: [DBMemory]
        if let eventId = memory.eventId {
            scoped = memoryStore.memories.filter { $0.eventId == eventId }
        } else {
            scoped = memoryStore.memories.filter { Calendar.current.isDate($0.date, inSameDayAs: memory.date) }
        }
        return scoped.isEmpty ? [memory] : scoped.sorted { $0.date > $1.date }
    }

    private func showRewindFromCuration() {
        showingRewind = true
        sheetSnap = .default_
    }

    private func applyAutoSelectionIfNeeded() {
        guard let autoSelectMemoryId,
              memoryStore.memories.contains(where: { $0.id == autoSelectMemoryId }) else { return }

        if selection.selectedPinID != autoSelectMemoryId {
            selection.select(pinID: autoSelectMemoryId)
        }
        activeSheetTab = .curation
        sheetSnap = .default_
        self.autoSelectMemoryId = nil
    }
}

enum MemoryMapHomeLayout {
    /// Prototype HTML `padding: '0 14px'` — 14pt.
    static let horizontalInset: CGFloat = UnfadingTheme.Spacing.sm2
    static let topChromeTop: CGFloat = 54
    static let topChromeHeight: CGFloat = 60
    static let topChromeRadius: CGFloat = 18
    static let filterChipTop: CGFloat = 108
    static let filterChipHeight: CGFloat = 44
    static let fabRight: CGFloat = 18
    static let fabBottomGap: CGFloat = 18
    /// Prototype HTML `right: 14`.
    static let mapControlsRight: CGFloat = UnfadingTheme.Spacing.sm2
    static let mapControlsSize: CGFloat = 40
    static let mapControlsSpacing: CGFloat = UnfadingTheme.Spacing.xs
    static let mapControlsStackHeight: CGFloat = (mapControlsSize * 2) + mapControlsSpacing
    /// Prototype HTML `bottom: calc(var(--sheet-height) + 88px)`.
    static let mapControlsBottomGap: CGFloat = 88

    static func sheetTopY(screenHeight: CGFloat, safeBottom: CGFloat, snap: BottomSheetSnap) -> CGFloat {
        let availableHeight = max(screenHeight - UnfadingTabBar.height - safeBottom, 1)
        let sheetHeight = availableHeight * CGFloat(snap.fraction)
        return screenHeight - UnfadingTabBar.height - safeBottom - sheetHeight
    }
}

private struct HomeChromeVisibilityModifier: ViewModifier {
    let snap: BottomSheetSnap

    func body(content: Content) -> some View {
        content
            .opacity(snap == .expanded ? 0 : 1)
            .allowsHitTesting(snap != .expanded)
            .animation(.easeInOut(duration: 0.22), value: snap)
    }
}

private struct MapControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

private extension View {
    func chromeVisibility(_ snap: BottomSheetSnap) -> some View {
        modifier(HomeChromeVisibilityModifier(snap: snap))
    }
}

#Preview {
    MemoryMapHomeView()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(GroupStore.preview())
        .environmentObject(CategoryStore.shared)
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
