import Photos
import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class RemoteImageViewTests: XCTestCase {
    func test_emptyPath_renderSmoke() {
        let view = RemoteImageView(storagePath: nil, uploader: EmptyPathUploader())
        XCTAssertNotNil(view.body)
    }

    func test_emptyStringPath_renderSmoke() {
        let view = RemoteImageView(storagePath: "", uploader: EmptyPathUploader())
        XCTAssertNotNil(view.body)
    }
}

private actor EmptyPathUploader: PhotoUploading {
    func upload(
        assets: [PHAsset],
        groupId: UUID,
        memoryId: UUID,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> [UploadedPhoto] {
        XCTFail("RemoteImageView should not upload while rendering")
        return []
    }

    func signedURL(storagePath: String, expiresIn: Int) async throws -> URL? {
        XCTFail("Empty storage paths should skip signed URL resolution")
        return nil
    }

    func delete(paths: [String]) async {}
}
