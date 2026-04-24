import Photos
import SwiftUI
import UIKit
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

    func test_loader_usesCachedImageWithoutResolvingSignedURL() async throws {
        let path = "group/memory/cached.jpg"
        let url = URL(string: "https://example.com/cached.jpg")!
        let uploader = SpyRemoteImageUploader()
        let loader = RemoteImageLoader()
        let image = Self.makeImage(color: .systemBlue)

        cache.store(url: url, for: path, expiresIn: 3_600)
        cache.store(image: image, for: path)

        await loader.load(
            storagePath: path,
            uploader: uploader,
            cache: cache,
            imageDataProvider: { _ in
                XCTFail("Image fetch should be skipped on cache hit")
                return Data()
            }
        )

        XCTAssertNotNil(loader.image)
        XCTAssertNil(loader.loadErrorMessage)
        let signedURLCalls = await uploader.signedURLCallCount
        XCTAssertEqual(signedURLCalls, 0)
    }

    func test_signedURLCache_removesAllObjectsOnMemoryWarning() {
        let path = "group/memory/flush.jpg"
        let url = URL(string: "https://example.com/flush.jpg")!

        cache.store(url: url, for: path, expiresIn: 3_600)
        cache.store(image: Self.makeImage(color: .systemPink), for: path)
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        XCTAssertNil(cache.url(for: path))
        XCTAssertNil(cache.image(for: path))
    }

    private static func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        return renderer.image { context in
            color.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
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

private actor SpyRemoteImageUploader: PhotoUploading {
    private(set) var signedURLCallCount = 0

    func upload(
        assets: [PHAsset],
        groupId: UUID,
        memoryId: UUID,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> [UploadedPhoto] {
        XCTFail("RemoteImageView should not upload while resolving images")
        return []
    }

    func signedURL(storagePath: String, expiresIn: Int) async throws -> URL? {
        signedURLCallCount += 1
        return URL(string: "https://example.com/\(storagePath)")
    }

    func delete(paths: [String]) async {}
}
