import SwiftUI
import UIKit

struct MemoryComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL

    private let initialLocationPermissionState: LocationPermissionState
    private let evidenceMode: MemoryComposerEvidenceMode

    @State private var note = ""
    @State private var selectedTags = Set<MemoryDraftTag>()
    @State private var selectedPlace = "Sangsu-dong rooftop"
    @State private var locationPermissionState: LocationPermissionState
    @State private var showingDeniedRecovery = false
    @State private var showingPlaceSearch = false
    @State private var didApplyEvidenceMode = false

    init(
        initialLocationPermissionState: LocationPermissionState = .denied,
        evidenceMode: MemoryComposerEvidenceMode = .none
    ) {
        self.initialLocationPermissionState = initialLocationPermissionState
        self.evidenceMode = evidenceMode
        _locationPermissionState = State(initialValue: initialLocationPermissionState)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Memory") {
                    TextField("Add a short note", text: $note, axis: .vertical)
                        .lineLimit(3...6)

                    LabeledContent("Event") {
                        Text("Tonight's rewind")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Time") {
                        Text("Today, 8:40 PM")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Photos") {
                    Button {
                    } label: {
                        Label("Add from Library", systemImage: "photo.on.rectangle")
                    }

                    Text("Your first photo can prefill time and place when metadata is available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Place") {
                    LabeledContent("Selected place") {
                        Text(selectedPlace)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showingPlaceSearch = true
                    } label: {
                        Label("Choose Place Manually", systemImage: "magnifyingglass")
                    }

                    Button {
                        handleCurrentLocationTap()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                }

                Section("Mood") {
                    tagCloud
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingDeniedRecovery) {
                LocationPermissionRecoverySheet(
                    selectedPlace: $selectedPlace,
                    showManualPlacePicker: $showingPlaceSearch,
                    openSettings: openSettings
                )
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPlaceSearch) {
                ManualPlacePickerSheet(selectedPlace: $selectedPlace)
                    .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                guard didApplyEvidenceMode == false else {
                    return
                }

                didApplyEvidenceMode = true
                locationPermissionState = initialLocationPermissionState

                switch evidenceMode {
                case .none:
                    break
                case .deniedRecovery:
                    showingDeniedRecovery = true
                case .manualPlacePicker:
                    selectedPlace = "Choose a place"
                    showingPlaceSearch = true
                }
            }
        }
    }

    private var tagCloud: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(MemoryDraftTag.samples.enumerated()), id: \.element.id) { _, tag in
                Button {
                    toggle(tag)
                } label: {
                    HStack(spacing: 12) {
                        Label(tag.title, systemImage: tag.systemImage)
                            .font(.body.weight(.semibold))
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func toggle(_ tag: MemoryDraftTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func handleCurrentLocationTap() {
        switch locationPermissionState {
        case .authorized:
            selectedPlace = "Current location"
        case .notDetermined, .denied, .restricted:
            showingDeniedRecovery = true
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }
}

private struct LocationPermissionRecoverySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlace: String
    @Binding var showManualPlacePicker: Bool

    let openSettings: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ContentUnavailableView {
                    Label("Location Access Off", systemImage: "location.slash")
                } description: {
                    Text("You can still save this memory by choosing a place manually, or re-enable location access in Settings for current-location autofill.")
                } actions: {
                    Button("Search for a Place") {
                        presentManualPlacePicker()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open Settings") {
                        openSettings()
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Current place", systemImage: "mappin.and.ellipse")
                        .font(.headline)
                    Text(selectedPlace)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .padding(.top, 12)
            .navigationTitle("Location Needed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func presentManualPlacePicker() {
        selectedPlace = "Choose a place"
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showManualPlacePicker = true
        }
    }
}

private struct ManualPlacePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlace: String
    @State private var searchText = ""

    private var filteredSuggestions: [PlaceSuggestion] {
        PlaceSuggestion.matching(searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    Section("Use typed place") {
                        Button {
                            select(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                        } label: {
                            Label(searchText.trimmingCharacters(in: .whitespacesAndNewlines), systemImage: "text.cursor")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                    }
                }

                Section("Nearby options") {
                    ForEach(filteredSuggestions) { suggestion in
                        Button {
                            select(suggestion.title)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: suggestion.systemImage)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suggestion.title)
                                        .foregroundStyle(.primary)
                                    Text(suggestion.subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 44, alignment: .leading)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search places")
            .navigationTitle("Choose Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func select(_ title: String) {
        selectedPlace = title
        dismiss()
    }
}

#Preview {
    MemoryComposerSheet()
}
