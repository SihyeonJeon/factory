import CoreLocation
import MapKit
import XCTest
@testable import MemoryMap

final class NearbyPlaceServiceTests: XCTestCase {
    func testDiscoveredPlaceEqualityConsidersCoordinate() {
        let a = DiscoveredPlace(
            id: "x",
            name: "상수 루프톱",
            coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            distanceMeters: 12,
            category: .cafe,
            address: "서울 마포구"
        )
        let b = DiscoveredPlace(
            id: "x",
            name: "상수 루프톱",
            coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            distanceMeters: 12,
            category: .cafe,
            address: "서울 마포구"
        )
        let c = DiscoveredPlace(
            id: "x",
            name: "상수 루프톱",
            coordinate: CLLocationCoordinate2D(latitude: 37.6, longitude: 127.0),
            distanceMeters: 12,
            category: .cafe,
            address: "서울 마포구"
        )
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testPickedPlaceEqualityAndConversion() {
        let place = DiscoveredPlace(
            id: "y",
            name: "한강공원",
            coordinate: CLLocationCoordinate2D(latitude: 37.52, longitude: 126.93),
            distanceMeters: 120,
            category: .park,
            address: "서울 영등포구"
        )
        let picked = place.pickedPlace
        XCTAssertEqual(picked.name, "한강공원")
        XCTAssertEqual(picked.coordinate.latitude, 37.52, accuracy: 0.0001)
        XCTAssertEqual(picked.coordinate.longitude, 126.93, accuracy: 0.0001)
        XCTAssertEqual(picked.address, "서울 영등포구")

        let other = PickedPlace(
            name: "한강공원",
            coordinate: CLLocationCoordinate2D(latitude: 37.52, longitude: 126.93),
            address: "서울 영등포구"
        )
        XCTAssertEqual(picked, other)
    }

    func testDiscoveredPlaceHashable() {
        let a = DiscoveredPlace(
            id: "z",
            name: "성수 카페",
            coordinate: CLLocationCoordinate2D(latitude: 37.544, longitude: 127.056),
            distanceMeters: 80,
            category: .cafe,
            address: nil
        )
        var set: Set<DiscoveredPlace> = []
        set.insert(a)
        set.insert(a)
        XCTAssertEqual(set.count, 1)
    }
}
