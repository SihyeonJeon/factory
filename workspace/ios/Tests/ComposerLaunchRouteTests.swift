import XCTest
@testable import MemoryMap

final class ComposerLaunchRouteTests: XCTestCase {
    func test_composerPhotoPathParsesAsTempFilePath() {
        let route = ComposerLaunchRoute.from(url: URL(string: "unfading://composer?photo=/tmp/foo.jpg")!)

        XCTAssertEqual(route?.photoReference, .tempFilePath("/tmp/foo.jpg"))
    }

    func test_composerPhotoIdentifierParsesAsAssetIdentifier() {
        let route = ComposerLaunchRoute.from(url: URL(string: "unfading://composer?photo=ABC123-IDENTIFIER")!)

        XCTAssertEqual(route?.photoReference, .assetIdentifier("ABC123-IDENTIFIER"))
    }
}
