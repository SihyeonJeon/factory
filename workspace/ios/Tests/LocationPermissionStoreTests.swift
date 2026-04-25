import CoreLocation
import XCTest
@testable import MemoryMap

@MainActor
final class LocationPermissionStoreTests: XCTestCase {
    func test_handleCurrentLocationTap_returns_centerOnUser_when_authorized() {
        let store = LocationPermissionStore(
            currentStatus: { .authorizedWhenInUse },
            requestWhenInUseAuthorization: {}
        )

        XCTAssertEqual(store.handleCurrentLocationTap(), .centerOnUser)
    }

    func test_handleCurrentLocationTap_requests_when_not_determined() {
        var didRequestAuthorization = false
        let store = LocationPermissionStore(
            currentStatus: { .notDetermined },
            requestWhenInUseAuthorization: { didRequestAuthorization = true }
        )

        XCTAssertEqual(store.handleCurrentLocationTap(), .requestSystemPermission)
        XCTAssertTrue(didRequestAuthorization)
    }

    func test_handleCurrentLocationTap_shows_recovery_when_denied() {
        let store = LocationPermissionStore(
            currentStatus: { .denied },
            requestWhenInUseAuthorization: {}
        )

        XCTAssertEqual(store.handleCurrentLocationTap(), .showRecoveryPrompt)
        XCTAssertEqual(store.recoveryPrompt?.state, .denied)
    }
}
