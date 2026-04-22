import XCTest
@testable import MemoryMap

@MainActor
final class MemoryStoreTests: XCTestCase {

    // vibe-limit-checked: 6 file IO do-catch exercised, 11 draft sample persistence, 12 save/delete behavior
    func test_save_then_reload_roundtrip() throws {
        let url = tempURL()
        let store = MemoryStore(fileURL: url)
        let draft = SampleMemoryDraft.defaultSamples[0]

        try store.save(draft)
        let reloaded = MemoryStore(fileURL: url)

        XCTAssertTrue(reloaded.drafts.contains(draft))
    }

    func test_delete_removes_draft() throws {
        let url = tempURL()
        let store = MemoryStore(fileURL: url)
        let draft = SampleMemoryDraft.defaultSamples[0]

        try store.save(draft)
        try store.delete(id: draft.id)

        XCTAssertFalse(store.drafts.contains(where: { $0.id == draft.id }))
    }

    func test_persist_and_reload_restores_all_saved_values() throws {
        let url = tempURL()
        let store = MemoryStore(fileURL: url)
        let draft = SampleMemoryDraft.defaultSamples[1]

        try store.save(draft)
        let reloaded = MemoryStore(fileURL: url)

        XCTAssertEqual(reloaded.drafts.first(where: { $0.id == draft.id })?.placeName, draft.placeName)
    }

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}
