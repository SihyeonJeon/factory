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

    func test_uploadImageData_retriesUntilSuccess() async throws {
        let client = StubPhotoUploaderClient(uploadFailuresBeforeSuccess: 2)
        let uploader = PhotoUploader(client: client)

        try await uploader.uploadImageData(Data([0x01]), path: "group/memory/retry.jpg")

        let attempts = await client.uploadAttempts
        XCTAssertEqual(attempts, 3)
    }

    func test_uploadImageData_throwsAfterThreeRetries() async {
        let client = StubPhotoUploaderClient(uploadFailuresBeforeSuccess: 4)
        let uploader = PhotoUploader(client: client)

        do {
            try await uploader.uploadImageData(Data([0x01]), path: "group/memory/fail.jpg")
            XCTFail("Expected upload to fail after retries")
        } catch let error as PhotoUploadError {
            XCTAssertEqual(error, .uploadFailed("stub upload failure"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let attempts = await client.uploadAttempts
        XCTAssertEqual(attempts, 4)
    }

    func test_validateImageDataSize_acceptsPayloadAtLimit() async throws {
        let uploader = PhotoUploader(client: StubPhotoUploaderClient(uploadFailuresBeforeSuccess: 0))
        let data = Data(count: 25 * 1024 * 1024)

        try await uploader.validateImageDataSize(data)
    }

    func test_validateImageDataSize_rejectsPayloadAboveLimit() async {
        let uploader = PhotoUploader(client: StubPhotoUploaderClient(uploadFailuresBeforeSuccess: 0))
        let data = Data(count: (25 * 1024 * 1024) + 1)

        do {
            try await uploader.validateImageDataSize(data)
            XCTFail("Expected oversized payload to be rejected")
        } catch let error as PhotoUploadError {
            XCTAssertEqual(error, .tooLarge(27))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
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

private actor StubPhotoUploaderClient: PhotoUploaderClient {
    private(set) var uploadAttempts = 0
    private let uploadFailuresBeforeSuccess: Int

    init(uploadFailuresBeforeSuccess: Int) {
        self.uploadFailuresBeforeSuccess = uploadFailuresBeforeSuccess
    }

    func upload(path: String, data: Data) async throws {
        uploadAttempts += 1
        if uploadAttempts <= uploadFailuresBeforeSuccess {
            throw StubError.uploadFailure
        }
    }

    func createSignedURL(path: String, expiresIn: Int) async throws -> URL? {
        URL(string: "https://example.com/\(path)")
    }

    func remove(paths: [String]) async throws {}
}

private enum StubError: LocalizedError {
    case uploadFailure

    var errorDescription: String? {
        "stub upload failure"
    }
}
