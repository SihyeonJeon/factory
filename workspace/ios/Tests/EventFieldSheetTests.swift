import XCTest
@testable import MemoryMap

@MainActor
final class EventFieldSheetTests: XCTestCase {
    func testExistingEventAutoSelectedWhenFound() async {
        let event = DBEvent(
            id: UUID(),
            groupId: UUID(),
            title: "성수 나들이",
            startDate: Date(timeIntervalSince1970: 1_776_000_000),
            endDate: nil,
            isMultiDay: false,
            createdAt: nil,
            reminderAt: nil
        )
        let model = EventFieldSheetModel(
            binding: .none,
            groupId: event.groupId,
            selectedTime: event.startDate,
            repository: StubEventRepository(existing: event)
        )

        await model.loadExistingEvent()

        XCTAssertEqual(model.binding, .bindExisting(event))
    }

    func testCreateNewBranchStoresTripFields() {
        let endDate = Date(timeIntervalSince1970: 1_776_086_400)
        let model = EventFieldSheetModel(
            binding: .none,
            groupId: UUID(),
            selectedTime: Date(timeIntervalSince1970: 1_776_000_000),
            repository: StubEventRepository(existing: nil)
        )
        model.createTitle = "부산 여행"
        model.isTrip = true
        model.endDate = endDate

        model.chooseCreateNew()

        XCTAssertEqual(model.binding, .createNew(title: "부산 여행", isTrip: true, endDate: endDate))
    }
}

private struct StubEventRepository: EventRepository {
    let existing: DBEvent?

    func plannedEvents(groupId: UUID, startUTC: Date, endUTC: Date) async throws -> [DBEvent] { [] }
    func monthlyExpenseKST(groupId: UUID, year: Int, month: Int) async throws -> Int64 { 0 }
    func createEvent(groupId: UUID, title: String, startDate: Date, endDate: Date?, reminderAt: Date?) async throws -> DBEvent {
        DBEvent(id: UUID(), groupId: groupId, title: title, startDate: startDate, endDate: endDate, isMultiDay: endDate != nil, createdAt: nil, reminderAt: reminderAt)
    }
    func findEventAt(groupId: UUID, timestamp: Date) async throws -> DBEvent? { existing }
}
