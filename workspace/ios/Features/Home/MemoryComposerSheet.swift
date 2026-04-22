import SwiftUI
import UIKit

struct MemoryComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL

    private let initialLocationPermissionState: LocationPermissionState
    private let evidenceMode: MemoryComposerEvidenceMode

    @StateObject private var state: MemoryComposerState
    @State private var showingDeniedRecovery = false
    @State private var showingPlaceSearch = false
    @State private var didApplyEvidenceMode = false

    init(
        initialLocationPermissionState: LocationPermissionState = .denied,
        evidenceMode: MemoryComposerEvidenceMode = .none
    ) {
        self.initialLocationPermissionState = initialLocationPermissionState
        self.evidenceMode = evidenceMode
        _state = StateObject(
            wrappedValue: MemoryComposerState(locationPermissionState: initialLocationPermissionState)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                    photoSection
                    placeSection
                    timeSection
                    noteSection
                    moodSection
                }
                .padding(.horizontal, UnfadingTheme.Spacing.xl)
                .padding(.vertical, UnfadingTheme.Spacing.lg)
            }
            .background(UnfadingTheme.Color.sheet)
            .navigationTitle(UnfadingLocalized.Composer.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(UnfadingLocalized.Composer.savePrimary)
                    }
                    .buttonStyle(.unfadingPrimary)
                    .disabled(state.isSaveEnabled == false)
                }
            }
            .sheet(isPresented: $showingDeniedRecovery) {
                LocationPermissionRecoverySheet(
                    selectedPlace: $state.selectedPlace,
                    showManualPlacePicker: $showingPlaceSearch,
                    openSettings: openSettings
                )
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPlaceSearch) {
                ManualPlacePickerSheet(selectedPlace: $state.selectedPlace)
                    .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear(perform: applyEvidenceModeIfNeeded)
        }
    }

    // vibe-limit-checked: 2 reusable UnfadingPhotoGrid, 8 Dynamic Type/a11y labels
    private var photoSection: some View {
        SectionContainer(title: UnfadingLocalized.Composer.photoSection) {
            UnfadingPhotoGrid(selection: $state.selectedPhotos)
        }
    }

    // vibe-limit-checked: 6 no silent failure in location path, 8 44pt edit/current-location targets
    private var placeSection: some View {
        SectionContainer(title: UnfadingLocalized.Composer.placeSection) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(UnfadingTheme.Color.primary)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                        Text(state.selectedPlace)
                            .font(UnfadingTheme.Font.subheadlineSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        Text(UnfadingLocalized.Composer.placeConfirmPrompt)
                            .font(UnfadingTheme.Font.subheadline())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Button(UnfadingLocalized.Composer.placeEditAction) {
                        showingPlaceSearch = true
                    }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
                }

                Button {
                    handleCurrentLocationTap()
                } label: {
                    Label(UnfadingLocalized.Composer.useCurrentLocation, systemImage: "location.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.unfadingPrimary)
            }
        }
    }

    // vibe-limit-checked: 8 DatePicker uses native wheel + Korean locale, no hardcoded font sizes
    private var timeSection: some View {
        SectionContainer(title: UnfadingLocalized.Composer.timeLabel) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                        Text(selectedTimeText)
                            .font(UnfadingTheme.Font.subheadlineSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        Text(UnfadingLocalized.Composer.timeInferredPrompt)
                            .font(UnfadingTheme.Font.subheadline())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                    Spacer()
                    Text(UnfadingLocalized.Composer.timeEditAction)
                        .font(UnfadingTheme.Font.footnoteSemibold())
                        .foregroundStyle(UnfadingTheme.Color.primary)
                }

                DatePicker(
                    UnfadingLocalized.Composer.timeLabel,
                    selection: $state.selectedTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))
            }
        }
    }

    // vibe-limit-checked: 8 Dynamic Type TextField with vertical growth and Korean placeholder
    private var noteSection: some View {
        SectionContainer(title: UnfadingLocalized.Composer.noteLabel) {
            TextField(UnfadingLocalized.Composer.noteField, text: $state.note, axis: .vertical)
                .lineLimit(3...8)
                .padding(UnfadingTheme.Spacing.md)
                .background(
                    UnfadingTheme.Color.card,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                )
        }
    }

    // vibe-limit-checked: 2 reused UnfadingFilterChip, 12 state transition tested by MemoryComposerStateTests
    private var moodSection: some View {
        SectionContainer(title: UnfadingLocalized.Composer.moodLabel) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(MemoryDraftTag.samples) { tag in
                        UnfadingFilterChip(
                            title: UnfadingLocalized.draftTag(id: tag.id, fallback: tag.title),
                            systemImage: tag.systemImage,
                            isSelected: state.selectedMoods.contains(tag)
                        ) {
                            state.toggleMood(tag)
                        }
                    }
                }
            }
        }
    }

    private var selectedTimeText: String {
        state.selectedTime.formatted(
            .dateTime
                .locale(Locale(identifier: "ko_KR"))
                .month()
                .day()
                .hour()
                .minute()
        )
    }

    private func applyEvidenceModeIfNeeded() {
        guard didApplyEvidenceMode == false else { return }
        didApplyEvidenceMode = true
        state.locationPermissionState = initialLocationPermissionState

        switch evidenceMode {
        case .none:
            break
        case .deniedRecovery:
            showingDeniedRecovery = true
        case .manualPlacePicker:
            state.setPlace(UnfadingLocalized.Composer.placeholderChoose)
            showingPlaceSearch = true
        }
    }

    private func handleCurrentLocationTap() {
        switch state.locationPermissionState {
        case .authorized:
            state.setPlace(UnfadingLocalized.Composer.placeholderCurrent)
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

private struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(title)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            content()
        }
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.cream, shadow: false)
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
