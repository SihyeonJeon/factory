import Foundation
import Photos
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
    @Published private(set) var uploadProgress: Double
    @Published private(set) var isUploading: Bool

    private let photoUploader: any PhotoUploading

    init(
        note: String = "",
        selectedPhotos: [PhotosPickerItem] = [],
        selectedPlace: String = UnfadingLocalized.Composer.samplePlace,
        selectedTime: Date = Date(),
        selectedMoods: Set<MemoryDraftTag> = [],
        locationPermissionState: LocationPermissionState = .denied,
        photoUploader: any PhotoUploading = PhotoUploader()
    ) {
        self.note = note
        self.selectedPhotos = selectedPhotos
        self.selectedPlace = selectedPlace
        self.selectedTime = selectedTime
        self.selectedMoods = selectedMoods
        self.locationPermissionState = locationPermissionState
        self.uploadProgress = 0
        self.isUploading = false
        self.photoUploader = photoUploader
    }

    var isSaveEnabled: Bool {
        (note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false || selectedPhotos.isEmpty == false)
            && isUploading == false
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
        uploadProgress = 0
        isUploading = false
    }

    func save(memoryStore: MemoryStore, authStore: AuthStore, groupStore: GroupStore) async throws {
        guard case let .signedIn(userId, _) = authStore.state else {
            throw SaveError.missingUser
        }
        guard let groupId = groupStore.activeGroupId else {
            throw SaveError.missingGroup
        }

        let memoryId = UUID()
        let selectedAssets = photoAssets()
        var uploadedPhotos: [UploadedPhoto] = []
        isUploading = selectedAssets.isEmpty == false
        uploadProgress = selectedAssets.isEmpty ? 0 : 0.01

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = selectedPlace.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedNote.split(separator: "\n").first.map(String.init) ?? fallbackTitle

        do {
            if selectedAssets.isEmpty == false {
                uploadedPhotos = try await photoUploader.upload(
                    assets: selectedAssets,
                    groupId: groupId,
                    memoryId: memoryId
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.uploadProgress = progress
                    }
                }
            }

            let photoPaths = uploadedPhotos.map(\.storagePath)
            let insert = DBMemoryInsert(
                id: memoryId,
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
                photoURL: photoPaths.first,
                photoURLs: photoPaths,
                categories: [],
                emotions: selectedMoods.map(\.id).sorted()
            )
            _ = try await memoryStore.createMemory(insert)
            reset()
        } catch {
            isUploading = false
            uploadProgress = 0
            await photoUploader.delete(paths: uploadedPhotos.map(\.storagePath))
            throw error
        }
    }

    private func photoAssets() -> [PHAsset] {
        let identifiers = selectedPhotos.compactMap(\.itemIdentifier)
        guard identifiers.isEmpty == false else { return [] }

        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
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
