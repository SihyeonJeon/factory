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
                let sheetHeight = proxy.size.height * CGFloat(selection.sheetSnap.fraction)

                ZStack(alignment: .bottom) {
                    mapLayer
                        .ignoresSafeArea(edges: .top)
                        .overlay(alignment: .top) {
                            topChrome
                                .padding(.horizontal, UnfadingTheme.Spacing.lg)
                                .padding(.top, UnfadingTheme.Spacing.sm)
                        }
                        .overlay(alignment: .topTrailing) {
                            filterRow
                                .padding(.top, 64)
                                .padding(.horizontal, UnfadingTheme.Spacing.md)
                        }

                    UnfadingBottomSheet(snap: $selection.sheetSnap) {
                        MemorySummaryCard(
                            selectedPin: selection.selectedPin(from: SampleMemoryPin.samples),
                            onDetailTap: openDetail
                        )
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .zIndex(1)

                    fab
                        .padding(.trailing, UnfadingTheme.Spacing.lg)
                        .padding(.bottom, sheetHeight + UnfadingTheme.Spacing.lg)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .opacity(selection.sheetSnap == .expanded ? 0 : 1)
                        .allowsHitTesting(selection.sheetSnap != .expanded)
                        .animation(reduceMotion ? nil : .interactiveSpring(response: 0.3, dampingFraction: 0.85), value: selection.sheetSnap)
                        .zIndex(2)
                }
            }
            .navigationTitle(UnfadingLocalized.Home.navTitle)
            .navigationBarTitleDisplayMode(.inline)
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
            .accessibilityLabel(UnfadingLocalized.Home.groupChipPlaceholder)
            .accessibilityHint(UnfadingLocalized.Home.groupChipHint)

            Spacer()

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
            HStack(spacing: UnfadingTheme.Spacing.xs) {
                Image(systemName: "plus")
                    .imageScale(.medium)
                Text(UnfadingLocalized.Home.addMemoryFab)
                    .font(UnfadingTheme.Font.footnoteSemibold())
            }
        }
        .buttonStyle(.unfadingPrimary)
        .accessibilityLabel(UnfadingLocalized.Accessibility.addMemoryLabel)
        .accessibilityHint(UnfadingLocalized.Accessibility.addMemoryHint)
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

#Preview {
    MemoryMapHomeView()
}
