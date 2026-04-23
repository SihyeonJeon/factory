import CoreLocation
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
    @Published var selectedAddress: String?
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedTime: Date
    @Published var selectedMoods: Set<MemoryDraftTag>
    @Published var locationPermissionState: LocationPermissionState
    /// 사진 메타데이터로 자동 채움이 적용된 상태 (banner 표시 / 수동 edit 시 해제).
    @Published private(set) var photoSeedApplied: PhotoSeedApplied
    /// 근처 장소 후보. refreshNearbyPlaces() 에서 채움.
    @Published private(set) var nearbyPlaces: [DiscoveredPlace]
    @Published private(set) var uploadProgress: Double
    @Published private(set) var isUploading: Bool

    private let photoUploader: any PhotoUploading
    private let placeResolver: PlaceResolving

    enum PhotoSeedApplied: Equatable {
        case none
        case locationAndTime
        case locationOnly
        case timeOnly
    }

    init(
        note: String = "",
        selectedPhotos: [PhotosPickerItem] = [],
        selectedPlace: String = UnfadingLocalized.Composer.samplePlace,
        selectedAddress: String? = nil,
        selectedCoordinate: CLLocationCoordinate2D? = nil,
        selectedTime: Date = Date(),
        selectedMoods: Set<MemoryDraftTag> = [],
        locationPermissionState: LocationPermissionState = .denied,
        photoUploader: any PhotoUploading = PhotoUploader(),
        placeResolver: PlaceResolving = NearbyPlaceService()
    ) {
        self.note = note
        self.selectedPhotos = selectedPhotos
        self.selectedPlace = selectedPlace
        self.selectedAddress = selectedAddress
        self.selectedCoordinate = selectedCoordinate
        self.selectedTime = selectedTime
        self.selectedMoods = selectedMoods
        self.locationPermissionState = locationPermissionState
        self.uploadProgress = 0
        self.isUploading = false
        self.photoSeedApplied = .none
        self.nearbyPlaces = []
        self.photoUploader = photoUploader
        self.placeResolver = placeResolver
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
        photoSeedApplied = .none
    }

    func setTime(_ value: Date) {
        selectedTime = value
        if photoSeedApplied == .locationAndTime {
            photoSeedApplied = .locationOnly
        } else if photoSeedApplied == .timeOnly {
            photoSeedApplied = .none
        }
    }

    /// F7: place picker / autocomplete 에서 선택된 장소 반영.
    func applyPickedPlace(_ picked: PickedPlace) {
        selectedPlace = picked.name
        selectedAddress = picked.address
        selectedCoordinate = picked.coordinate
        photoSeedApplied = .none
        Task { await refreshNearbyPlaces() }
    }

    /// F6/F7: 첫 사진의 메타데이터로 시각·좌표를 자동 채움.
    /// 이미 사용자가 수정한 필드는 override 하지 않음 (selectedCoordinate == nil 이고 selectedPlace 가 samplePlace 일 때만).
    func applyPhotoSeed(_ seed: PhotoSeed) async {
        let placeSlotEmpty = selectedPlace == UnfadingLocalized.Composer.samplePlace
            || selectedPlace.isEmpty
            || selectedPlace == UnfadingLocalized.Composer.placeholderChoose
        var tookTime = false
        var tookLocation = false
        if let creationDate = seed.creationDate, abs(selectedTime.timeIntervalSince(Date())) < 5 {
            selectedTime = creationDate
            tookTime = true
        }
        if let coord = seed.coordinate, selectedCoordinate == nil {
            selectedCoordinate = coord
            if placeSlotEmpty {
                if let match = try? await placeResolver.closestMatch(to: coord) {
                    selectedPlace = match.name
                    selectedAddress = match.address
                } else {
                    selectedPlace = UnfadingLocalized.Composer.placeholderCurrent
                }
            }
            tookLocation = true
            await refreshNearbyPlaces()
        }
        photoSeedApplied = {
            switch (tookTime, tookLocation) {
            case (true, true): return .locationAndTime
            case (true, false): return .timeOnly
            case (false, true): return .locationOnly
            default: return .none
            }
        }()
    }

    /// F5: 선택된 좌표 반경 500m 근처 장소 top-5.
    func refreshNearbyPlaces(radiusMeters: Double = 500) async {
        guard let coord = selectedCoordinate else {
            nearbyPlaces = []
            return
        }
        do {
            let results = try await placeResolver.nearby(coord, radiusMeters: radiusMeters)
            nearbyPlaces = Array(results.prefix(5))
        } catch {
            nearbyPlaces = []
        }
    }

    /// F3: 장소 이름으로 직접 자동완성 검색.
    func searchPlaceByName(_ query: String) async -> [DiscoveredPlace] {
        (try? await placeResolver.searchByName(query, near: selectedCoordinate)) ?? []
    }

    /// F6/F7: 현재 selectedPhotos 중 첫 번째의 PHAsset에서 seed 를 추출해 적용.
    /// identifier 없는 picker item(예: stub)은 무시.
    func applyFirstPhotoSeedIfAvailable() async {
        guard let first = selectedPhotos.first, let identifier = first.itemIdentifier else { return }
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetch.firstObject else { return }
        let seed = PhotoMetadataExtractor.extract(from: asset)
        await applyPhotoSeed(seed)
    }

    func reset() {
        note = ""
        selectedPhotos = []
        selectedPlace = UnfadingLocalized.Composer.samplePlace
        selectedAddress = nil
        selectedCoordinate = nil
        selectedTime = Date()
        selectedMoods = []
        locationPermissionState = .denied
        uploadProgress = 0
        isUploading = false
        photoSeedApplied = .none
        nearbyPlaces = []
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
            let coord = selectedCoordinate
            let insert = DBMemoryInsert(
                id: memoryId,
                userId: userId,
                groupId: groupId,
                title: title.isEmpty ? fallbackTitle : title,
                note: trimmedNote,
                placeTitle: fallbackTitle.isEmpty ? UnfadingLocalized.Composer.samplePlace : fallbackTitle,
                address: selectedAddress,
                locationLat: coord?.latitude ?? 37.5665,
                locationLng: coord?.longitude ?? 126.9780,
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
