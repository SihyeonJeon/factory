import XCTest
@testable import MemoryMap

final class DeepLinkRouterTests: XCTestCase {
    private let memoryID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1")!
    private let eventID = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2")!

    func test_parse_custom_memory_link() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "unfading://memory/\(memoryID.uuidString)")!),
            .memory(memoryID)
        )
    }

    func test_parse_custom_event_link() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "unfading://event/\(eventID.uuidString)")!),
            .event(eventID)
        )
    }

    func test_parse_custom_composer_link_with_photo() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "unfading://composer?photo=local-identifier-123")!),
            .composer(preSelectedPhotoID: "local-identifier-123")
        )
    }

    func test_parse_custom_composer_link_without_photo() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "unfading://composer")!),
            .composer(preSelectedPhotoID: nil)
        )
    }

    func test_parse_custom_rewind_link() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "unfading://rewind")!),
            .rewind
        )
    }

    func test_parse_universal_memory_link() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "https://unfading.app/memory/\(memoryID.uuidString)")!),
            .memory(memoryID)
        )
    }

    func test_parse_universal_event_link() {
        XCTAssertEqual(
            DeepLinkRouter.parse(URL(string: "https://unfading.app/event/\(eventID.uuidString)")!),
            .event(eventID)
        )
    }

    func test_rejects_unknown_host() {
        XCTAssertNil(DeepLinkRouter.parse(URL(string: "https://example.com/memory/\(memoryID.uuidString)")!))
    }

    func test_rejects_invalid_uuid() {
        XCTAssertNil(DeepLinkRouter.parse(URL(string: "unfading://memory/not-a-uuid")!))
    }

    func test_rejects_unknown_route() {
        XCTAssertNil(DeepLinkRouter.parse(URL(string: "unfading://settings")!))
    }
}
