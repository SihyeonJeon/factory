import XCTest
import CoreLocation
@testable import MemoryMap

final class MemoryMapTests: XCTestCase {
    func testSamplePinsExist() {
        XCTAssertFalse(SampleMemoryPin.samples.isEmpty)
    }

    func testRewindMomentsExist() {
        XCTAssertFalse(RewindMoment.samples.isEmpty)
    }

    func testPlaceSuggestionMatchingUsesTitleAndSubtitle() {
        XCTAssertEqual(PlaceSuggestion.matching("").count, PlaceSuggestion.samples.count)
        XCTAssertEqual(PlaceSuggestion.matching("Jeju").map(\.title), ["Jeju Sunrise Trail"])
        XCTAssertEqual(PlaceSuggestion.matching("Mapo").map(\.title), ["Sangsu Rooftop"])
    }

    @MainActor
    func testCurrentLocationTapRequestsAuthorizationWhenUndetermined() {
        var requestCount = 0
        let store = LocationPermissionStore(
            currentStatus: { .notDetermined },
            requestWhenInUseAuthorization: { requestCount += 1 }
        )

        let result = store.handleCurrentLocationTap()

        XCTAssertEqual(result, .requestSystemPermission)
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(store.permissionState, .notDetermined)
        XCTAssertNil(store.recoveryPrompt)
    }

    @MainActor
    func testDeniedLocationTapShowsSettingsAndManualFallback() {
        let store = LocationPermissionStore(
            currentStatus: { .denied },
            requestWhenInUseAuthorization: {}
        )

        let result = store.handleCurrentLocationTap()

        XCTAssertEqual(result, .showRecoveryPrompt)
        XCTAssertEqual(store.permissionState, .denied)
        XCTAssertEqual(store.recoveryPrompt?.actions, [.openSettings, .continueWithoutLocation])
        XCTAssertFalse(store.isUsingManualFallback)
    }

    @MainActor
    func testRestrictedLocationTapShowsManualFallbackOnly() {
        let store = LocationPermissionStore(
            currentStatus: { .restricted },
            requestWhenInUseAuthorization: {}
        )

        let result = store.handleCurrentLocationTap()

        XCTAssertEqual(result, .showRecoveryPrompt)
        XCTAssertEqual(store.permissionState, .restricted)
        XCTAssertEqual(store.recoveryPrompt?.actions, [.continueWithoutLocation])
        XCTAssertFalse(store.isUsingManualFallback)
    }

    @MainActor
    func testAuthorizedLocationTapCentersOnUser() {
        let store = LocationPermissionStore(
            currentStatus: { .authorizedWhenInUse },
            requestWhenInUseAuthorization: {}
        )

        let result = store.handleCurrentLocationTap()

        XCTAssertEqual(result, .centerOnUser)
        XCTAssertEqual(store.permissionState, .authorized)
        XCTAssertNil(store.recoveryPrompt)
        XCTAssertFalse(store.isUsingManualFallback)
    }

    @MainActor
    func testContinueWithoutLocationEnablesManualFallbackAndDismissesPrompt() {
        let store = LocationPermissionStore(
            currentStatus: { .denied },
            requestWhenInUseAuthorization: {}
        )

        _ = store.handleCurrentLocationTap()
        let result = store.handleRecoveryAction(.continueWithoutLocation)

        XCTAssertEqual(result, .continueWithoutLocation)
        XCTAssertTrue(store.isUsingManualFallback)
        XCTAssertNil(store.recoveryPrompt)
    }

    @MainActor
    func testOpenSettingsKeepsManualFallbackDisabled() {
        let store = LocationPermissionStore(
            currentStatus: { .denied },
            requestWhenInUseAuthorization: {}
        )

        _ = store.handleCurrentLocationTap()
        let result = store.handleRecoveryAction(.openSettings)

        XCTAssertEqual(result, .openSettings)
        XCTAssertFalse(store.isUsingManualFallback)
        XCTAssertNil(store.recoveryPrompt)
    }

    @MainActor
    func testRefreshClearsManualFallbackAfterAuthorizationReturns() {
        var status: CLAuthorizationStatus = .denied
        let store = LocationPermissionStore(
            currentStatus: { status },
            requestWhenInUseAuthorization: {}
        )

        _ = store.handleCurrentLocationTap()
        _ = store.handleRecoveryAction(.continueWithoutLocation)
        XCTAssertTrue(store.isUsingManualFallback)

        status = .authorizedWhenInUse
        store.refresh()

        XCTAssertEqual(store.permissionState, .authorized)
        XCTAssertFalse(store.isUsingManualFallback)
    }
}
