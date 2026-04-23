import Photos
import XCTest
@testable import MemoryMap

final class PhotoUploaderTests: XCTestCase {
    func test_storagePath_usesGroupMemoryFilenamePattern() {
        let groupId = UUID(uuidString: "11111111-1111-4111-8111-111111111117")!
        let memoryId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!

        let path = PhotoUploader.storagePath(groupId: groupId, memoryId: memoryId, filename: "cover.jpg")

        XCTAssertEqual(path, "11111111-1111-4111-8111-111111111117/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/cover.jpg")
        XCTAssertEqual(path.split(separator: "/").count, 3)
        XCTAssertTrue(path.hasSuffix(".jpg"))
    }

    func test_emptyUpload_isMockFreeSmokeAndDoesNotUpload() async throws {
        let uploaded = try await PhotoUploader().upload(
            assets: [],
            groupId: UUID(),
            memoryId: UUID()
        )

        XCTAssertTrue(uploaded.isEmpty)
    }

    func test_fakeUploader_canRepresentStorageOnlyResult() async throws {
        let fake = FakePhotoUploader()
        let groupId = UUID(uuidString: "11111111-1111-4111-8111-111111111117")!
        let memoryId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!

        let uploaded = try await fake.upload(assets: [], groupId: groupId, memoryId: memoryId) { _ in }

        XCTAssertEqual(uploaded.first?.storagePath, "\(groupId.uuidString.lowercased())/\(memoryId.uuidString.lowercased())/fake.jpg")
    }
}

private actor FakePhotoUploader: PhotoUploading {
    func upload(
        assets: [PHAsset],
        groupId: UUID,
        memoryId: UUID,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> [UploadedPhoto] {
        progress(1)
        return [
            UploadedPhoto(
                storagePath: PhotoUploader.storagePath(groupId: groupId, memoryId: memoryId, filename: "fake.jpg"),
                remoteURL: nil,
                width: 100,
                height: 100,
                bytes: 1
            )
        ]
    }

    func signedURL(storagePath: String, expiresIn: Int) async throws -> URL? {
        nil
    }

    func delete(paths: [String]) async {}
}
