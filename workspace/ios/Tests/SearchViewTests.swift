import XCTest
@testable import MemoryMap

@MainActor
final class SearchViewTests: XCTestCase {
    func test_emptyQuery_showsRecentSearches() {
        let defaults = isolatedDefaults()
        let recentStore = SearchRecentStore(defaults: defaults, key: "search.tests.recent")
        _ = recentStore.record("상수")
        _ = recentStore.record("joy")
        let model = SearchViewModel(
            groupId: UUID(),
            repository: StubSearchMemoryRepository(),
            recentStore: recentStore
        )

        model.loadRecentSearches()
        model.query = "   "

        XCTAssertEqual(model.trimmedQuery, "")
        XCTAssertEqual(model.visibleRecentSearches, ["joy", "상수"])
    }

    func test_clearRecentSearches_removesPersistedValues() {
        let defaults = isolatedDefaults()
        let recentStore = SearchRecentStore(defaults: defaults, key: "search.tests.recent")
        _ = recentStore.record("한강")
        let model = SearchViewModel(
            groupId: UUID(),
            repository: StubSearchMemoryRepository(),
            recentStore: recentStore
        )

        model.loadRecentSearches()
        model.clearRecentSearches()

        XCTAssertEqual(model.visibleRecentSearches, [])
        XCTAssertEqual(recentStore.load(), [])
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "SearchViewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

private struct StubSearchMemoryRepository: MemoryRepository {
    func fetchMemories(groupId: UUID) async throws -> [DBMemory] { [] }
    func searchMemories(groupId: UUID, query: String) async throws -> [DBMemory] { [] }
    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory { throw URLError(.badServerResponse) }
    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory { throw URLError(.badServerResponse) }
    func deleteMemory(id: UUID) async throws {}
}
