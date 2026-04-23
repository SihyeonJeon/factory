import XCTest
@testable import MemoryMap

@MainActor
final class MemoryDetailTests: XCTestCase {

    func test_event_carousel_scope_keeps_index_inside_same_event() {
        let eventA = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1")!
        let eventB = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1")!
        let first = makeMemory(id: 1, eventId: eventA, title: "첫 번째")
        let second = makeMemory(id: 2, eventId: eventA, title: "두 번째")
        let outside = makeMemory(id: 3, eventId: eventB, title: "다른 이벤트")

        let scoped = MemoryDetailEventScope.scopedMemories(memory: second, eventMemories: [first, second, outside])

        XCTAssertEqual(scoped.map(\.id), [first.id, second.id])
        XCTAssertEqual(MemoryDetailEventScope.initialIndex(memory: second, eventMemories: [first, second, outside]), 1)
        XCTAssertEqual(MemoryDetailEventScope.boundedIndex(current: 1, delta: 1, count: scoped.count), 1)
        XCTAssertEqual(MemoryDetailEventScope.boundedIndex(current: 1, delta: -1, count: scoped.count), 0)
    }

    func test_participants_section_only_shows_for_general_group() {
        XCTAssertTrue(MemoryDetailEventScope.showsParticipantsSection(mode: .general))
        XCTAssertFalse(MemoryDetailEventScope.showsParticipantsSection(mode: .couple))
    }

    func test_add_one_line_allows_only_one_submission() {
        XCTAssertTrue(MemoryDetailExtraLinePolicy.canSubmit(line: "다음엔 더 오래 머물기", didSubmit: false))
        XCTAssertFalse(MemoryDetailExtraLinePolicy.canSubmit(line: "두 번째 문장", didSubmit: true))
        XCTAssertFalse(MemoryDetailExtraLinePolicy.canSubmit(line: "   ", didSubmit: false))
    }

    func test_memory_detail_view_builds_with_db_memory_inputs() {
        let eventId = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-ccccccccccc1")!
        let memory = makeMemory(id: 1, eventId: eventId, title: "상세")
        XCTAssertNotNil(
            MemoryDetailView(
                memory: memory,
                eventMemories: [memory, makeMemory(id: 2, eventId: eventId, title: "같은 이벤트")],
                participants: [makeProfile(id: memory.userId, name: "시현")],
                mode: .general
            )
        )
    }

    private func makeMemory(id: Int, eventId: UUID?, title: String) -> DBMemory {
        DBMemory(
            id: UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", id))!,
            userId: UUID(uuidString: "10000000-0000-4000-8000-000000000001")!,
            groupId: UUID(uuidString: "20000000-0000-4000-8000-000000000001")!,
            eventId: eventId,
            title: title,
            note: "기록",
            placeTitle: "상수 루프톱",
            address: "서울 마포구",
            locationLat: 37.5519,
            locationLng: 126.9215,
            date: Date(timeIntervalSince1970: 1_776_000_000 + TimeInterval(id * 60)),
            capturedAt: nil,
            photoURL: nil,
            photoURLs: [],
            categories: ["food"],
            emotions: ["joy"],
            participantUserIds: [UUID(uuidString: "10000000-0000-4000-8000-000000000001")!],
            cost: 18_500,
            reactionCount: 0,
            createdAt: nil
        )
    }

    private func makeProfile(id: UUID, name: String) -> DBProfile {
        DBProfile(
            id: id,
            email: nil,
            displayName: name,
            photoURL: nil,
            createdAt: nil
        )
    }
}
