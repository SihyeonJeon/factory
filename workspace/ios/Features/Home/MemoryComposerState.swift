import Foundation
import PhotosUI
import SwiftUI

// vibe-limit-checked: 5 @MainActor state ownership, 12 behavior-testable state transitions
@MainActor
final class MemoryComposerState: ObservableObject {
    @Published var note: String
    @Published var selectedPhotos: [PhotosPickerItem]
    @Published var selectedPlace: String
    @Published var selectedTime: Date
    @Published var selectedMoods: Set<MemoryDraftTag>
    @Published var locationPermissionState: LocationPermissionState

    init(
        note: String = "",
        selectedPhotos: [PhotosPickerItem] = [],
        selectedPlace: String = UnfadingLocalized.Composer.samplePlace,
        selectedTime: Date = Date(),
        selectedMoods: Set<MemoryDraftTag> = [],
        locationPermissionState: LocationPermissionState = .denied
    ) {
        self.note = note
        self.selectedPhotos = selectedPhotos
        self.selectedPlace = selectedPlace
        self.selectedTime = selectedTime
        self.selectedMoods = selectedMoods
        self.locationPermissionState = locationPermissionState
    }

    var isSaveEnabled: Bool {
        note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false || selectedPhotos.isEmpty == false
    }

    func toggleMood(_ mood: MemoryDraftTag) {
        if selectedMoods.contains(mood) {
            selectedMoods.remove(mood)
        } else {
            selectedMoods.insert(mood)
        }
    }

    func setNote(_ value: String) {
        note = value
    }

    func setPlace(_ value: String) {
        selectedPlace = value
    }

    func setTime(_ value: Date) {
        selectedTime = value
    }

    func reset() {
        note = ""
        selectedPhotos = []
        selectedPlace = UnfadingLocalized.Composer.samplePlace
        selectedTime = Date()
        selectedMoods = []
        locationPermissionState = .denied
    }
}
