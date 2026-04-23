import CoreLocation
import XCTest
@testable import MemoryMap

@MainActor
final class MemoryComposerLocationSeedTests: XCTestCase {
    func testApplyPhotoSeedFillsPlaceAndTimeWhenEmpty() async {
        let resolver = StubPlaceResolver(
            closest: DiscoveredPlace(
                id: "seed-1",
                name: "매칭된 장소",
                coordinate: CLLocationCoordinate2D(latitude: 37.55, longitude: 126.98),
                distanceMeters: 12,
                category: nil,
                address: "서울 어딘가"
            )
        )
        let state = MemoryComposerState(placeResolver: resolver)
        let seedDate = Date(timeIntervalSince1970: 1_776_000_000)
        await state.applyPhotoSeed(
            PhotoSeed(
                creationDate: seedDate,
                coordinate: CLLocationCoordinate2D(latitude: 37.55, longitude: 126.98),
                heading: nil
            )
        )
        XCTAssertEqual(state.selectedTime, seedDate)
        XCTAssertEqual(state.selectedPlace, "매칭된 장소")
        XCTAssertEqual(state.selectedAddress, "서울 어딘가")
        XCTAssertEqual(state.photoSeedApplied, .locationAndTime)
    }

    func testApplyPickedPlaceOverridesSeed() async {
        let state = MemoryComposerState(placeResolver: StubPlaceResolver())
        state.applyPickedPlace(
            PickedPlace(
                name: "수동 선택",
                coordinate: CLLocationCoordinate2D(latitude: 37.49, longitude: 127.01),
                address: "강남"
            )
        )
        XCTAssertEqual(state.selectedPlace, "수동 선택")
        XCTAssertEqual(state.selectedAddress, "강남")
        XCTAssertEqual(state.photoSeedApplied, .none)
    }

    func testRefreshNearbyPlacesWithoutCoordinateClearsList() async {
        let state = MemoryComposerState(placeResolver: StubPlaceResolver(nearby: [
            DiscoveredPlace(
                id: "n1",
                name: "근처1",
                coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
                distanceMeters: 50,
                category: nil
            )
        ]))
        await state.refreshNearbyPlaces()
        XCTAssertTrue(state.nearbyPlaces.isEmpty)
    }

    func testPhotoSeedAppliedLocationOnlyWhenTimeAlreadyUserEdited() async {
        let state = MemoryComposerState(placeResolver: StubPlaceResolver(
            closest: DiscoveredPlace(
                id: "c",
                name: "closest",
                coordinate: CLLocationCoordinate2D(latitude: 37.55, longitude: 126.98),
                distanceMeters: 0,
                category: nil
            )
        ))
        // user edits time → selectedTime is far from now
        let userPicked = Date(timeIntervalSince1970: 1_770_000_000)
        state.setTime(userPicked)
        await state.applyPhotoSeed(
            PhotoSeed(
                creationDate: Date(timeIntervalSince1970: 1_776_000_000),
                coordinate: CLLocationCoordinate2D(latitude: 37.55, longitude: 126.98),
                heading: nil
            )
        )
        XCTAssertEqual(state.selectedTime, userPicked)
        XCTAssertEqual(state.photoSeedApplied, .locationOnly)
    }
}

// MARK: Stub

private actor StubPlaceResolver: PlaceResolving {
    let closest: DiscoveredPlace?
    let nearby: [DiscoveredPlace]
    let search: [DiscoveredPlace]

    init(
        closest: DiscoveredPlace? = nil,
        nearby: [DiscoveredPlace] = [],
        search: [DiscoveredPlace] = []
    ) {
        self.closest = closest
        self.nearby = nearby
        self.search = search
    }

    func searchByName(_ query: String, near: CLLocationCoordinate2D?) async throws -> [DiscoveredPlace] { search }
    func nearby(_ center: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [DiscoveredPlace] { nearby }
    func closestMatch(to coord: CLLocationCoordinate2D) async throws -> DiscoveredPlace? { closest }
}
