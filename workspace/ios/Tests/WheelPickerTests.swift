import XCTest
@testable import MemoryMap

final class WheelPickerTests: XCTestCase {
    func testHourRangeIs24HourClock() {
        XCTAssertEqual(WheelPicker.hourRange.first, 0)
        XCTAssertEqual(WheelPicker.hourRange.last, 23)
        XCTAssertEqual(WheelPicker.hourRange.count, 24)
    }

    func testMinuteRangeIsFullHour() {
        XCTAssertEqual(WheelPicker.minuteRange.first, 0)
        XCTAssertEqual(WheelPicker.minuteRange.last, 59)
        XCTAssertEqual(WheelPicker.minuteRange.count, 60)
    }
}
