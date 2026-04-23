import XCTest
@testable import MemoryMap

@MainActor
final class RSVPStoreTests: XCTestCase {
    func test_summary_counts_statuses_in_contract_format() {
        let store = RSVPStore(rsvps: [
            UUID(uuidString: "11111111-1111-4111-8111-111111111117")!: .going,
            UUID(uuidString: "22222222-2222-4222-8222-222222222227")!: .going,
            UUID(uuidString: "33333333-3333-4333-8333-333333333337")!: .going,
            UUID(uuidString: "44444444-4444-4444-8444-444444444447")!: .maybe
        ])

        XCTAssertEqual(store.summary, "✓ 3 · ? 1 · ✗ 0")
    }

    func test_toggle_sets_and_clears_status() {
        let userId = UUID(uuidString: "11111111-1111-4111-8111-111111111117")!
        let store = RSVPStore()

        store.toggle(.going, for: userId)
        XCTAssertEqual(store.rsvps[userId], .going)

        store.toggle(.going, for: userId)
        XCTAssertNil(store.rsvps[userId])
    }
}
