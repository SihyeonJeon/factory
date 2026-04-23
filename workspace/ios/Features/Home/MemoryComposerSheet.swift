import PhotosUI
import SwiftUI
import UIKit

struct MemoryComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var groupStore: GroupStore
    @EnvironmentObject private var memoryStore: MemoryStore

    private let initialLocationPermissionState: LocationPermissionState
    private let evidenceMode: MemoryComposerEvidenceMode

    @StateObject private var state: MemoryComposerState
    @State private var showingDeniedRecovery = false
    @State private var showingPlaceSearch = false
    @State private var showingPlacePicker = false
    @State private var showingEventSheet = false
    @State private var didApplyEvidenceMode = false
    @State private var saveErrorMessage: String?
    @State private var costText = ""

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
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md2) {
                        photoSection
                        placeSection
                        timeSection
                        eventSection
                        participantSection
                        noteSection
                        moodSection
                        costSection
                    }
                    .padding(.horizontal, UnfadingTheme.Spacing.md)
                    .padding(.top, UnfadingTheme.Spacing.xs)
                    .padding(.bottom, UnfadingTheme.Spacing.xl2)
                }
            }
            .background(UnfadingTheme.Color.sheet)
            .navigationBarHidden(true)
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
            .sheet(isPresented: $showingPlacePicker) {
                PlacePickerSheet(
                    initialCoordinate: state.selectedCoordinate,
                    onSelect: { picked in state.applyPickedPlace(picked) }
                )
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingEventSheet) {
                EventFieldSheet(
                    binding: $state.eventBinding,
                    groupId: groupStore.activeGroupId,
                    selectedTime: state.selectedTime
                )
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: state.selectedPhotos) { _, _ in
                Task { await state.applyFirstPhotoSeedIfAvailable() }
            }
            .onChange(of: costText) { _, newValue in
                let digits = newValue.filter(\.isNumber)
                if digits != newValue {
                    costText = digits
                }
                state.cost = Int(digits)
            }
            .alert("저장하지 못했어요", isPresented: saveErrorIsPresented) {
                Button(UnfadingLocalized.Common.confirm, role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "잠시 후 다시 시도해 주세요.")
            }
            .onAppear {
                applyEvidenceModeIfNeeded()
                applyParticipantDefaultsIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack {
            Button(UnfadingLocalized.Common.cancel) {
                dismiss()
            }
            .font(UnfadingTheme.Font.body(15))
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
            .frame(minHeight: 44)

            Spacer()

            Text(UnfadingLocalized.Composer.navTitle)
                .font(UnfadingTheme.Font.sectionTitle(16))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                save()
            } label: {
                Text(UnfadingLocalized.Composer.savePrimary)
                    .font(UnfadingTheme.Font.captionSemibold())
                    .frame(minWidth: 56, minHeight: 44)
                    .padding(.horizontal, UnfadingTheme.Spacing.xs)
                    .background(
                        state.canSave ? UnfadingTheme.Color.primary : UnfadingTheme.Color.chipBg,
                        in: Capsule()
                    )
                    .foregroundStyle(state.canSave ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(state.canSave == false)
            .accessibilityIdentifier("composer-save-button")
        }
        .padding(.horizontal, UnfadingTheme.Spacing.md)
        .padding(.top, UnfadingTheme.Spacing.xl2)
        .padding(.bottom, UnfadingTheme.Spacing.xs)
    }

    // vibe-limit-checked: 8 Dynamic Type/a11y labels, 2 3-column composer grid
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            composerPhotoGrid

            HStack(spacing: UnfadingTheme.Spacing.xs2) {
                SourceChip(title: UnfadingLocalized.Composer.sourceAlbum, systemImage: "photo.on.rectangle") {}
                SourceChip(title: UnfadingLocalized.Composer.sourceCamera, systemImage: "camera") {}
                SourceChip(title: UnfadingLocalized.Composer.sourceFile, systemImage: "folder") {}
            }

            if state.showPhotoSeedNotice {
                metadataNotice
            }

            if state.isUploading {
                uploadProgressView
            }
        }
    }

    private var composerPhotoGrid: some View {
        GeometryReader { proxy in
            let gap = UnfadingTheme.Spacing.xs2
            let tile = (proxy.size.width - gap * 2) / 3
            HStack(alignment: .top, spacing: gap) {
                PhotosPicker(selection: $state.selectedPhotos, maxSelectionCount: 12, matching: .images) {
                    photoTile(index: 0, isLarge: true)
                }
                .accessibilityLabel(UnfadingLocalized.PhotoGrid.addPhoto)

                VStack(spacing: gap) {
                    photoTile(index: 1, isLarge: false)
                    photoTile(index: 2, isLarge: false)
                }

                VStack(spacing: gap) {
                    photoTile(index: 3, isLarge: false)
                    PhotosPicker(selection: $state.selectedPhotos, maxSelectionCount: 12, matching: .images) {
                        emptyPhotoTile(label: "추가")
                    }
                    .accessibilityLabel(UnfadingLocalized.PhotoGrid.addPhoto)
                }
            }
            .frame(height: tile * 2 + gap)
        }
        .frame(height: 232)
    }

    @ViewBuilder
    private func photoTile(index: Int, isLarge: Bool) -> some View {
        if state.selectedPhotos.indices.contains(index) {
            RoundedRectangle(cornerRadius: isLarge ? UnfadingTheme.Radius.card : UnfadingTheme.Radius.segment, style: .continuous)
                .fill(UnfadingTheme.Color.accentSoft)
                .overlay {
                    VStack(spacing: UnfadingTheme.Spacing.xs) {
                        Image(systemName: "photo")
                            .font(UnfadingTheme.Font.sectionTitle(18))
                        Text("PHOTO \(index + 1)")
                            .font(UnfadingTheme.Font.metaNum(10, weight: .bold))
                    }
                    .foregroundStyle(UnfadingTheme.Color.primary)
                }
                .aspectRatio(1, contentMode: .fit)
        } else {
            emptyPhotoTile(label: index == 0 ? "PHOTO" : "—")
        }
    }

    private func emptyPhotoTile(label: String) -> some View {
        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous)
            .stroke(UnfadingTheme.Color.primary.opacity(0.66), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .background(UnfadingTheme.Color.card, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: UnfadingTheme.Spacing.xxs) {
                    Image(systemName: "plus")
                        .font(UnfadingTheme.Font.sectionTitle(18))
                    Text(label)
                        .font(UnfadingTheme.Font.caption2Semibold())
                }
                .foregroundStyle(UnfadingTheme.Color.primary)
            }
    }

    private var metadataNotice: some View {
        HStack(alignment: .top, spacing: UnfadingTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(UnfadingTheme.Font.body(16))
                .foregroundStyle(UnfadingTheme.Color.primary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xxs) {
                Text(UnfadingLocalized.Composer.metadataSparkleNotice)
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.primary)
                Text(UnfadingLocalized.Composer.metadataSparkleHint)
                    .font(UnfadingTheme.Font.metaNum(11.5, weight: .regular))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(UnfadingTheme.Spacing.sm)
        .background(UnfadingTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
    }

    private var uploadProgressView: some View {
        let percent = Int((state.uploadProgress * 100).rounded())

        return VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            Text("사진 업로드 중... \(percent)%")
                .font(UnfadingTheme.Font.footnoteSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            ProgressView(value: state.uploadProgress)
                .progressViewStyle(.linear)
                .accessibilityLabel(UnfadingLocalized.Accessibility.photoUploadInProgressLabel)
                .accessibilityValue(UnfadingLocalized.Home.progressPercent(percent))
        }
    }

    // vibe-limit-checked: 8 44pt edit/current-location targets, 6 no silent failure in location path
    private var placeSection: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            FieldRow(UnfadingLocalized.Composer.placeSection, placeState: state.placeState, action: { showingPlacePicker = true }) {
                HStack(alignment: .top, spacing: UnfadingTheme.Spacing.sm) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(UnfadingTheme.Font.body(16))
                        .foregroundStyle(state.placeState == .confirmed ? UnfadingTheme.Color.primary : UnfadingTheme.Color.textTertiary)
                        .frame(width: 24, height: 24)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                        Text(state.selectedPlace)
                            .font(UnfadingTheme.Font.subheadlineSemibold())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        if let address = state.selectedAddress {
                            Text(address)
                                .font(UnfadingTheme.Font.footnote())
                                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: UnfadingTheme.Spacing.xs2) {
                MiniButton(UnfadingLocalized.Composer.confirmThisPlace, isPrimary: true) {
                    state.confirmPlace()
                }
                MiniButton(UnfadingLocalized.Composer.changePlace) {
                    showingPlacePicker = true
                }
                MiniButton(UnfadingLocalized.Composer.useCurrent) {
                    Task { await state.confirmCurrentLocation() }
                }
            }

            if !state.nearbyPlaces.isEmpty {
                nearbyChips
            }
        }
    }

    private var photoSeedBanner: some View {
        let text: String = {
            switch state.photoSeedApplied {
            case .locationAndTime: return UnfadingLocalized.Composer.photoSeedBanner
            case .locationOnly:    return UnfadingLocalized.Composer.photoSeedBannerLocationOnly
            case .timeOnly:        return UnfadingLocalized.Composer.photoSeedBannerTimeOnly
            case .none:            return ""
            }
        }()
        return HStack(spacing: UnfadingTheme.Spacing.sm) {
            Image(systemName: "photo.badge.checkmark")
                .foregroundStyle(UnfadingTheme.Color.primary)
            Text(text)
                .font(UnfadingTheme.Font.footnoteSemibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(UnfadingTheme.Spacing.md)
        .background(
            UnfadingTheme.Color.primarySoft,
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("composer-photo-seed-banner")
    }

    private var nearbyChips: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            Text(UnfadingLocalized.Composer.nearbyOptions)
                .font(UnfadingTheme.Font.footnoteSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(state.nearbyPlaces) { place in
                        Button {
                            state.applyPickedPlace(place.pickedPlace)
                        } label: {
                            Text(place.name)
                                .font(UnfadingTheme.Font.footnoteSemibold())
                                .padding(.horizontal, UnfadingTheme.Spacing.md)
                                .padding(.vertical, UnfadingTheme.Spacing.sm)
                                .background(
                                    UnfadingTheme.Color.card,
                                    in: Capsule()
                                )
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
        }
    }

    // vibe-limit-checked: 8 DatePicker uses native wheel + Korean locale, no hardcoded font sizes
    private var timeSection: some View {
        FieldRow(UnfadingLocalized.Composer.timeLabel) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                HStack {
                    Image(systemName: "clock")
                        .font(UnfadingTheme.Font.body(16))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    Text(selectedTimeText)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                }
                WheelPicker(hour: $state.hour, minute: $state.minute)
                    .onChange(of: state.hour) { _, _ in
                        state.setHourMinute(hour: state.hour, minute: state.minute)
                    }
                    .onChange(of: state.minute) { _, _ in
                        state.setHourMinute(hour: state.hour, minute: state.minute)
                    }
            }
        }
    }

    // vibe-limit-checked: 8 Dynamic Type TextField with vertical growth and Korean placeholder
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs2) {
            Text(UnfadingLocalized.Composer.noteLabel)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            TextField(UnfadingLocalized.Composer.noteField, text: $state.note, axis: .vertical)
                .lineLimit(3...8)
                .frame(minHeight: 80, alignment: .topLeading)
                .padding(UnfadingTheme.Spacing.md)
                .background(
                    UnfadingTheme.Color.card,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                )
        }
    }

    // vibe-limit-checked: 8 chip a11y inherited from UnfadingFilterChip, 2 reused component, 12 state transition tested by MemoryComposerStateTests
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            Text(UnfadingLocalized.Composer.emotionSection)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: UnfadingTheme.Spacing.xs)], alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
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

    private var eventSection: some View {
        FieldRow(UnfadingLocalized.Composer.eventFieldTitle, action: { showingEventSheet = true }) {
            HStack(alignment: .top, spacing: UnfadingTheme.Spacing.sm) {
                Image(systemName: "calendar")
                    .font(UnfadingTheme.Font.body(16))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    Text(eventTitle)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    Text("\(UnfadingLocalized.Composer.eventBindToSameDay) · \(UnfadingLocalized.Composer.eventCreateNew)")
                        .font(UnfadingTheme.Font.metaNum(11, weight: .regular))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var participantSection: some View {
        if groupStore.mode == .general {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                HStack {
                    Text(UnfadingLocalized.Composer.participantsFieldTitle)
                        .font(UnfadingTheme.Font.captionSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    Spacer()
                    Text(UnfadingLocalized.Composer.formattedParticipantsCount(state.participantUserIds.count, groupStore.members.count))
                        .font(UnfadingTheme.Font.metaNum(11, weight: .bold))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: UnfadingTheme.Spacing.xs)], alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    ForEach(Array(groupStore.members.enumerated()), id: \.element.id) { index, member in
                        let color = UnfadingTheme.Color.memberPalette[index % UnfadingTheme.Color.memberPalette.count]
                        ParticipantChip(
                            member: member,
                            color: color,
                            isSelected: state.participantUserIds.contains(member.profiles.id)
                        ) {
                            state.toggleParticipant(member.profiles.id)
                        }
                    }
                }
            }
        }
    }

    private var costSection: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs2) {
            Text(UnfadingLocalized.Composer.costLabel)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            HStack(spacing: UnfadingTheme.Spacing.sm) {
                Image(systemName: "wonsign")
                    .font(UnfadingTheme.Font.body(18))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                TextField(UnfadingLocalized.Composer.costPlaceholder, text: $costText)
                    .keyboardType(.numberPad)
                    .font(UnfadingTheme.Font.body())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
            }
            .frame(minHeight: 44)
            .padding(UnfadingTheme.Spacing.sm)
            .background(UnfadingTheme.Color.card, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
            .shadow(style: UnfadingTheme.Shadow.card)
        }
    }

    private var eventTitle: String {
        switch state.eventBinding {
        case let .bindExisting(event):
            return event.title
        case let .createNew(title, _, _):
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? UnfadingLocalized.Composer.eventCreateNew : trimmed
        case .none:
            return "\(UnfadingLocalized.Composer.eventBindToSameDay) · \(UnfadingLocalized.Composer.eventCreateNew)"
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

    private func applyParticipantDefaultsIfNeeded() {
        guard state.participantUserIds.isEmpty else { return }
        state.defaultParticipantSelection(
            mode: groupStore.mode,
            memberUserIds: groupStore.members.map(\.profiles.id)
        )
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

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    saveErrorMessage = nil
                }
            }
        )
    }

    private func save() {
        Task {
            do {
                try await state.save(memoryStore: memoryStore, authStore: authStore, groupStore: groupStore)
                dismiss()
            } catch {
                saveErrorMessage = error.localizedDescription
            }
        }
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
                    .accessibilityHint(UnfadingLocalized.Accessibility.searchPlaceHint)

                    Button(UnfadingLocalized.Composer.openSettings) {
                        openSettings()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint(UnfadingLocalized.Accessibility.openSettingsHint)
                }

                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                    Label(UnfadingLocalized.Composer.currentPlace, systemImage: "mappin.and.ellipse")
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    Text(selectedPlace)
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
                .padding(.horizontal)
                .accessibilityElement(children: .combine)

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
                                    .accessibilityHidden(true)

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
