import XCTest
@testable import MemoryMap

final class AppIntentsTests: XCTestCase {
    func test_shortcuts_provider_registers_three_shortcuts() {
        XCTAssertEqual(UnfadingShortcutsProvider.appShortcuts.count, 3)
    }

    func test_show_today_memories_intent_targets_rewind() async throws {
        let intent = ShowTodayMemoriesIntent()

        XCTAssertEqual(intent.targetURL, URL(string: "unfading://rewind"))

        let result = try await intent.perform()
        XCTAssertTrue(String(reflecting: type(of: result)).contains("OpenURLIntent"))
    }

    func test_new_memory_intent_targets_composer() async throws {
        let intent = NewMemoryIntent()

        XCTAssertEqual(intent.targetURL, URL(string: "unfading://composer"))

        let result = try await intent.perform()
        XCTAssertTrue(String(reflecting: type(of: result)).contains("OpenURLIntent"))
    }

    func test_show_calendar_intent_targets_calendar_tab() async throws {
        let intent = ShowCalendarIntent()

        XCTAssertEqual(intent.targetURL, URL(string: "unfading://calendar"))

        let result = try await intent.perform()
        XCTAssertTrue(String(reflecting: type(of: result)).contains("OpenURLIntent"))
    }
}
