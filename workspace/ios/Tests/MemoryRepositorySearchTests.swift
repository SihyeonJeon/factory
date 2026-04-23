import XCTest
@testable import MemoryMap

final class MemoryRepositorySearchTests: XCTestCase {
    func test_searchFilter_includesTextAndTagPredicates() {
        XCTAssertEqual(
            SupabaseMemoryRepository.searchFilter(query: "Joy"),
            "place_title.ilike.%Joy%,note.ilike.%Joy%,title.ilike.%Joy%,categories.cs.{joy},emotions.cs.{joy}"
        )
    }

    func test_searchFilter_trimsWhitespaceAndRejectsEmptyQuery() {
        XCTAssertEqual(
            SupabaseMemoryRepository.searchFilter(query: "  한강  "),
            "place_title.ilike.%한강%,note.ilike.%한강%,title.ilike.%한강%,categories.cs.{한강},emotions.cs.{한강}"
        )
        XCTAssertNil(SupabaseMemoryRepository.searchFilter(query: "   "))
    }
}
