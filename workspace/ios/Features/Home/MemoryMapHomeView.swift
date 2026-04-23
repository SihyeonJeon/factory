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
    private let evidenceMode: MemoryComposerEvidenceMode
    @StateObject private var locationPermissionStore = LocationPermissionStore()
    @StateObject private var selection = MemorySelectionState()
    @State private var showingComposer = false
    @State private var didPresentEvidenceComposer = false
    @State private var showingGroupHub = false
    @State private var detailPin: SampleMemoryPin?
    @State private var measuredSheetHeight: CGFloat = 0
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    init(evidenceMode: MemoryComposerEvidenceMode = .none) {
        self.evidenceMode = evidenceMode
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    mapLayer
                        .ignoresSafeArea(edges: .top)

                    topChrome
                        .padding(.horizontal, MemoryMapHomeLayout.horizontalInset)
                        .padding(.top, MemoryMapHomeLayout.topChromeTop)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .zIndex(2)

                    filterRow
                        .padding(.horizontal, MemoryMapHomeLayout.horizontalInset)
                        .padding(.top, MemoryMapHomeLayout.filterChipTop)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .zIndex(2)

                    UnfadingBottomSheet(snap: $selection.sheetSnap, measuredHeight: $measuredSheetHeight) {
                        MemorySummaryCard(
                            selectedPin: selection.selectedPin(from: SampleMemoryPin.samples),
                            onDetailTap: openDetail
                        )
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .zIndex(4)

                    mapControls
                        .padding(.trailing, MemoryMapHomeLayout.mapControlsRight)
                        .padding(.bottom, measuredSheetHeight + MemoryMapHomeLayout.mapControlsBottomGap)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .zIndex(3)

                    fab
                        .padding(.trailing, MemoryMapHomeLayout.fabRight)
                        .padding(.bottom, measuredSheetHeight + MemoryMapHomeLayout.fabBottomGap)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .opacity(selection.sheetSnap == .expanded ? 0 : 1)
                        .allowsHitTesting(selection.sheetSnap != .expanded)
                        .animation(reduceMotion ? .easeInOut(duration: 0.25) : .interpolatingSpring(stiffness: 260, damping: 32), value: measuredSheetHeight)
                        .zIndex(5)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingComposer) {
                MemoryComposerSheet(
                    initialLocationPermissionState: .denied,
                    evidenceMode: evidenceMode
                )
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingGroupHub) {
                GroupHubView()
            }
            .navigationDestination(item: $detailPin) { pin in
                MemoryDetailView(pin: pin)
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
            .onAppear {
                guard evidenceMode != .none, didPresentEvidenceComposer == false else { return }
                didPresentEvidenceComposer = true
                showingComposer = true
            }
        }
    }

    // MARK: Layers

    private var mapLayer: some View {
        Map(position: $cameraPosition, selection: .constant(nil as UUID?)) {
            ForEach(SampleMemoryPin.samples) { pin in
                Annotation(pin.title, coordinate: pin.coordinate) {
                    Button {
                        selection.select(pinID: pin.id)
                    } label: {
                        MemoryPinMarker(pin: pin)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(UnfadingLocalized.Accessibility.mapPinLabel(title: pin.title))
                    .accessibilityHint(UnfadingLocalized.Accessibility.mapPinHint)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    private var topChrome: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            Button {
                showingGroupHub = true
            } label: {
                HStack(spacing: UnfadingTheme.Spacing.xs) {
                    Image(systemName: "person.2.fill")
                        .imageScale(.small)
                    Text(UnfadingLocalized.Home.groupChipPlaceholder)
                        .font(UnfadingTheme.Font.footnoteSemibold())
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                }
                .padding(.horizontal, UnfadingTheme.Spacing.md)
                .padding(.vertical, UnfadingTheme.Spacing.sm)
                .frame(minHeight: 44)
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .background(
                    UnfadingTheme.Color.sheet,
                    in: Capsule()
                )
                .shadow(color: UnfadingTheme.Color.shadow, radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(UnfadingLocalized.Home.groupChipPlaceholder)
            .accessibilityHint(UnfadingLocalized.Home.groupChipHint)

            Button {
                // Search stub — full implementation in a future round.
            } label: {
                Image(systemName: "magnifyingglass")
                    .imageScale(.medium)
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(UnfadingTheme.Color.sheet, in: Circle())
                    .shadow(color: UnfadingTheme.Color.shadow, radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Home.searchLabel)
            .accessibilityHint(UnfadingLocalized.Home.searchHint)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UnfadingTheme.Spacing.sm) {
                ForEach(MemorySelectionState.Filter.allCases, id: \.self) { filter in
                    UnfadingFilterChip(
                        title: filter.title,
                        isSelected: selection.activeFilter == filter
                    ) {
                        selection.toggleFilter(filter)
                    }
                }
            }
            .padding(.horizontal, UnfadingTheme.Spacing.sm)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(UnfadingLocalized.Accessibility.filterRowLabel)
        .accessibilityHint(UnfadingLocalized.Accessibility.filterRowHint)
    }

    private var fab: some View {
        Button {
            showingComposer = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: 56, height: 56)
                .background(UnfadingTheme.Color.primary.gradient, in: Circle())
                .shadow(color: UnfadingTheme.Color.primary.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(UnfadingLocalized.Accessibility.addMemoryLabel)
        .accessibilityHint(UnfadingLocalized.Accessibility.addMemoryHint)
    }

    private var mapControls: some View {
        VStack(spacing: UnfadingTheme.Spacing.sm) {
            mapControlButton(systemName: "location.fill", accessibilityLabel: "Current location") {
                _ = locationPermissionStore.handleCurrentLocationTap()
            }

            mapControlButton(systemName: "location.north.line.fill", accessibilityLabel: "Reset map orientation") {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                    )
                )
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.25) : .interpolatingSpring(stiffness: 260, damping: 32), value: measuredSheetHeight)
    }

    private func mapControlButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .imageScale(.medium)
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .frame(width: 44, height: 44)
                .background(UnfadingTheme.Color.sheet, in: Circle())
                .shadow(color: UnfadingTheme.Color.shadow, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
        detailPin = selection.selectedPin(from: SampleMemoryPin.samples) ?? SampleMemoryPin.samples.first
    }
}

enum MemoryMapHomeLayout {
    static let horizontalInset: CGFloat = 14
    static let topChromeTop: CGFloat = 54
    static let filterChipTop: CGFloat = 108
    static let fabRight: CGFloat = 18
    static let fabBottomGap: CGFloat = 18
    static let mapControlsRight: CGFloat = 14
    static let mapControlsBottomGap: CGFloat = 88
}

#Preview {
    MemoryMapHomeView()
        .environmentObject(AuthStore(preview: .signedIn(userId: UUID(), email: "preview@example.com")))
        .environmentObject(GroupStore.preview())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
