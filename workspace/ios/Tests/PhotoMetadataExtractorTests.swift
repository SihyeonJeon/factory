import CoreLocation
import XCTest
@testable import MemoryMap

final class PhotoMetadataExtractorTests: XCTestCase {
    func testExtractReturnsSeedFromCreationDateAndLocation() {
        let date = Date(timeIntervalSince1970: 1_776_000_000)
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.55, longitude: 126.98),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 45,
            speed: 0,
            timestamp: date
        )
        let seed = PhotoMetadataExtractor.extract(creationDate: date, location: location)
        XCTAssertEqual(seed.creationDate, date)
        XCTAssertEqual(seed.coordinate?.latitude ?? 0, 37.55, accuracy: 0.0001)
        XCTAssertEqual(seed.coordinate?.longitude ?? 0, 126.98, accuracy: 0.0001)
        XCTAssertEqual(seed.heading ?? 0, 45, accuracy: 0.001)
    }

    func testExtractHandlesMissingLocation() {
        let seed = PhotoMetadataExtractor.extract(creationDate: nil, location: nil)
        XCTAssertNil(seed.creationDate)
        XCTAssertNil(seed.coordinate)
        XCTAssertNil(seed.heading)
    }

    func testSeedEquality() {
        let date = Date(timeIntervalSince1970: 1_776_000_000)
        let lhs = PhotoSeed(
            creationDate: date,
            coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            heading: 10
        )
        let rhs = PhotoSeed(
            creationDate: date,
            coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            heading: 10
        )
        XCTAssertEqual(lhs, rhs)
    }
}
