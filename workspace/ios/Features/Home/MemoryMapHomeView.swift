import MapKit
import SwiftUI
import UIKit

struct MemoryMapHomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    private let evidenceMode: MemoryComposerEvidenceMode
    @StateObject private var locationPermissionStore = LocationPermissionStore()
    @State private var showingComposer = false
    @State private var didPresentEvidenceComposer = false
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
            Map(position: $cameraPosition) {
                ForEach(SampleMemoryPin.samples) { pin in
                    Annotation(pin.title, coordinate: pin.coordinate) {
                        MemoryPinMarker(pin: pin)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .top)
            .safeAreaInset(edge: .bottom) {
                MemorySummaryCard()
                    .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 16 : 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            .navigationTitle("Memory Map")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleCurrentLocationTap()
                    } label: {
                        Image(systemName: "location")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel("Show current location")
                    .accessibilityHint("Centers the map on your current location when permission is available.")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingComposer = true
                    } label: {
                        if dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "plus")
                        } else {
                            Label("New Memory", systemImage: "plus")
                        }
                    }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityLabel("Add memory")
                }
            }
            .sheet(isPresented: $showingComposer) {
                MemoryComposerSheet(
                    initialLocationPermissionState: .denied,
                    evidenceMode: evidenceMode
                )
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                locationPermissionStore.recoveryPrompt?.title ?? "",
                isPresented: recoveryPromptIsPresented,
                titleVisibility: .visible
            ) {
                if let recoveryPrompt = locationPermissionStore.recoveryPrompt {
                    ForEach(recoveryPrompt.actions) { action in
                        Button(action.title) {
                            handleRecoveryAction(action)
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    locationPermissionStore.dismissRecoveryPrompt()
                }
            } message: {
                if let recoveryPrompt = locationPermissionStore.recoveryPrompt {
                    Text(recoveryPrompt.message)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }

                locationPermissionStore.refresh()
            }
            .onAppear {
                guard evidenceMode != .none, didPresentEvidenceComposer == false else {
                    return
                }

                didPresentEvidenceComposer = true
                showingComposer = true
            }
        }
    }

    private var recoveryPromptIsPresented: Binding<Bool> {
        Binding(
            get: { locationPermissionStore.recoveryPrompt != nil },
            set: { isPresented in
                if isPresented == false {
                    locationPermissionStore.dismissRecoveryPrompt()
                }
            }
        )
    }

    private func handleCurrentLocationTap() {
        let result = locationPermissionStore.handleCurrentLocationTap()

        guard result == .centerOnUser else {
            return
        }

        cameraPosition = .userLocation(
            followsHeading: false,
            fallback: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                )
            )
        )
    }

    private func handleRecoveryAction(_ action: LocationPermissionRecoveryAction) {
        switch locationPermissionStore.handleRecoveryAction(action) {
        case .openSettings:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            openURL(settingsURL)
        case .continueWithoutLocation:
            break
        }
    }
}

#Preview {
    MemoryMapHomeView()
}
