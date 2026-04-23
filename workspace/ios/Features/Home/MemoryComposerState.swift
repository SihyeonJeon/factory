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

    func save(memoryStore: MemoryStore, authStore: AuthStore, groupStore: GroupStore) async throws {
        guard case let .signedIn(userId, _) = authStore.state else {
            throw SaveError.missingUser
        }
        guard let groupId = groupStore.activeGroupId else {
            throw SaveError.missingGroup
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = selectedPlace.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedNote.split(separator: "\n").first.map(String.init) ?? fallbackTitle
        let insert = DBMemoryInsert(
            userId: userId,
            groupId: groupId,
            title: title.isEmpty ? fallbackTitle : title,
            note: trimmedNote,
            placeTitle: fallbackTitle.isEmpty ? UnfadingLocalized.Composer.samplePlace : fallbackTitle,
            address: nil,
            locationLat: 37.5665,
            locationLng: 126.9780,
            date: selectedTime,
            capturedAt: selectedTime,
            photoURL: nil,
            photoURLs: [],
            categories: [],
            emotions: selectedMoods.map(\.id).sorted()
        )
        _ = try await memoryStore.createMemory(insert)
        reset()
    }

    enum SaveError: LocalizedError {
        case missingUser
        case missingGroup

        var errorDescription: String? {
            switch self {
            case .missingUser:
                return "로그인이 필요해요."
            case .missingGroup:
                return "활성 그룹을 찾을 수 없어요."
            }
        }
    }
}
