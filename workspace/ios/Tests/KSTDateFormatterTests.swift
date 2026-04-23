import XCTest
@testable import MemoryMap

final class KSTDateFormatterTests: XCTestCase {
    func testStartOfMonthKSTReturnsUTCMidnightMinusNineHours() {
        // KST 2026-05-01 00:00 == UTC 2026-04-30 15:00
        let kstStart = KSTDateFormatter.startOfMonthKST(year: 2026, month: 5)
        let comps = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(identifier: "UTC")!, from: kstStart)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 4)
        XCTAssertEqual(comps.day, 30)
        XCTAssertEqual(comps.hour, 15)
        XCTAssertEqual(comps.minute, 0)
    }

    func testEndOfMonthKSTExclusive() {
        // end(2026-12) == start(2027-01)
        let end = KSTDateFormatter.endOfMonthKST(year: 2026, month: 12)
        let next = KSTDateFormatter.startOfMonthKST(year: 2027, month: 1)
        XCTAssertEqual(end, next)
    }

    func testIsFutureKSTNoon() {
        // now: KST 2026-04-23 17:00, 내일(2026-04-24 00:00) 은 미래
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = KSTDateFormatter.timeZone
        let now = cal.date(from: DateComponents(year: 2026, month: 4, day: 23, hour: 17, minute: 0))!
        let tomorrow = cal.date(from: DateComponents(year: 2026, month: 4, day: 24, hour: 0, minute: 0))!
        let yesterday = cal.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 23, minute: 59))!
        XCTAssertTrue(KSTDateFormatter.isFuture(tomorrow, now: now))
        XCTAssertFalse(KSTDateFormatter.isFuture(yesterday, now: now))
    }

    func testIsFutureMidnightBoundary() {
        // KST midnight boundary: 2026-04-23 00:00 KST — UTC 쪽으로 transition해도 오늘 으로 간주돼야 함
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = KSTDateFormatter.timeZone
        let now = cal.date(from: DateComponents(year: 2026, month: 4, day: 23, hour: 0, minute: 1))!
        let todayMidnight = cal.date(from: DateComponents(year: 2026, month: 4, day: 23, hour: 0, minute: 0))!
        XCTAssertFalse(KSTDateFormatter.isFuture(todayMidnight, now: now))
    }

    func testCurrentYearMonthKST() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = KSTDateFormatter.timeZone
        let now = cal.date(from: DateComponents(year: 2026, month: 4, day: 23, hour: 12, minute: 0))!
        let (y, m) = KSTDateFormatter.currentYearMonth(now)
        XCTAssertEqual(y, 2026)
        XCTAssertEqual(m, 4)
    }
}
