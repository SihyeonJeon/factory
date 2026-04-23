import Photos
import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class RemoteImageViewTests: XCTestCase {
    private var cache: RemoteImageSignedURLCache!
    private var now: Date!

    override func setUp() {
        super.setUp()
        now = Date(timeIntervalSince1970: 1_900_000_000)
        cache = RemoteImageSignedURLCache(now: { [unowned self] in now })
    }

    func test_emptyPath_renderSmoke() {
        let view = RemoteImageView(storagePath: nil, uploader: EmptyPathUploader())
        XCTAssertNotNil(view.body)
    }

    func test_emptyStringPath_renderSmoke() {
        let view = RemoteImageView(storagePath: "", uploader: EmptyPathUploader())
        XCTAssertNotNil(view.body)
    }

    func test_signedURLCache_returnsHitWhenExpiryOutsideRefreshWindow() {
        let url = URL(string: "https://example.com/a.jpg")!

        cache.store(url: url, for: "group/memory/a.jpg", expiresIn: 601)

        XCTAssertEqual(cache.url(for: "group/memory/a.jpg"), url)
    }

    func test_signedURLCache_returnsMissInsideRefreshWindow() {
        let url = URL(string: "https://example.com/b.jpg")!
        cache.store(url: url, for: "group/memory/b.jpg", expiresIn: 301)

        now = now.addingTimeInterval(2)

        XCTAssertNil(cache.url(for: "group/memory/b.jpg"))
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
