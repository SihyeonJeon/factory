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
    @State private var selectedPlace = UnfadingLocalized.Composer.samplePlace
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
                Section(UnfadingLocalized.Composer.memorySection) {
                    TextField(UnfadingLocalized.Composer.noteField, text: $note, axis: .vertical)
                        .lineLimit(3...6)

                    LabeledContent(UnfadingLocalized.Composer.eventLabel) {
                        Text(UnfadingLocalized.Summary.tonightsRewind)
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }

                    LabeledContent(UnfadingLocalized.Composer.timeLabel) {
                        Text(UnfadingLocalized.Composer.sampleTime)
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                }

                Section(UnfadingLocalized.Composer.photosSection) {
                    Button {
                    } label: {
                        Label(UnfadingLocalized.Composer.addFromLibrary, systemImage: "photo.on.rectangle")
                    }

                    Text(UnfadingLocalized.Composer.metadataHint)
                        .font(UnfadingTheme.Font.subheadline())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(UnfadingLocalized.Composer.placeSection) {
                    LabeledContent(UnfadingLocalized.Composer.selectedPlace) {
                        Text(selectedPlace)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }

                    Button {
                        showingPlaceSearch = true
                    } label: {
                        Label(UnfadingLocalized.Composer.choosePlaceManually, systemImage: "magnifyingglass")
                    }

                    Button {
                        handleCurrentLocationTap()
                    } label: {
                        Label(UnfadingLocalized.Composer.useCurrentLocation, systemImage: "location.fill")
                    }
                }

                Section(UnfadingLocalized.Composer.moodSection) {
                    tagCloud
                }
            }
            .navigationTitle(UnfadingLocalized.Composer.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(UnfadingLocalized.Composer.save) {
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
                    selectedPlace = UnfadingLocalized.Composer.placeholderChoose
                    showingPlaceSearch = true
                }
            }
        }
    }

    private var tagCloud: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            ForEach(Array(MemoryDraftTag.samples.enumerated()), id: \.element.id) { _, tag in
                Button {
                    toggle(tag)
                } label: {
                    HStack(spacing: UnfadingTheme.Spacing.md) {
                        Label(UnfadingLocalized.draftTag(id: tag.id, fallback: tag.title), systemImage: tag.systemImage)
                            .font(UnfadingTheme.Font.subheadlineSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(UnfadingTheme.Color.primary)
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
            selectedPlace = UnfadingLocalized.Composer.placeholderCurrent
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
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                ContentUnavailableView {
                    Label(UnfadingLocalized.Composer.locationAccessOff, systemImage: "location.slash")
                } description: {
                    Text(UnfadingLocalized.Composer.locationRecoveryHint)
                } actions: {
                    Button(UnfadingLocalized.Composer.searchForPlace) {
                        presentManualPlacePicker()
                    }
                    .buttonStyle(.unfadingPrimary)

                    Button(UnfadingLocalized.Composer.openSettings) {
                        openSettings()
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                    Label(UnfadingLocalized.Composer.currentPlace, systemImage: "mappin.and.ellipse")
                        .font(.headline)
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    Text(selectedPlace)
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .padding(.top, UnfadingTheme.Spacing.md)
            .navigationTitle(UnfadingLocalized.Composer.locationNeededTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Composer.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func presentManualPlacePicker() {
        selectedPlace = UnfadingLocalized.Composer.placeholderChoose
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
                    Section(UnfadingLocalized.Composer.useTypedPlace) {
                        Button {
                            select(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                        } label: {
                            Label(searchText.trimmingCharacters(in: .whitespacesAndNewlines), systemImage: "text.cursor")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                    }
                }

                Section(UnfadingLocalized.Composer.nearbyOptions) {
                    ForEach(filteredSuggestions) { suggestion in
                        let localized = UnfadingLocalized.placeSuggestion(
                            id: suggestion.id,
                            fallbackTitle: suggestion.title,
                            fallbackSubtitle: suggestion.subtitle
                        )
                        Button {
                            select(localized.title)
                        } label: {
                            HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
                                Image(systemName: suggestion.systemImage)
                                    .foregroundStyle(UnfadingTheme.Color.primary)
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                                    Text(localized.title)
                                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                                    Text(localized.subtitle)
                                        .font(UnfadingTheme.Font.subheadline())
                                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 44, alignment: .leading)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: UnfadingLocalized.Composer.searchPlaces)
            .navigationTitle(UnfadingLocalized.Composer.choosePlaceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
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
