import CoreLocation
import Foundation

enum LocationPermissionState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    init(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            self = .authorized
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        @unknown default:
            self = .restricted
        }
    }
}

enum LocationPermissionRecoveryAction: String, Equatable, Identifiable {
    case openSettings
    case continueWithoutLocation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openSettings:
            return "Open Settings"
        case .continueWithoutLocation:
            return "Continue Without Location"
        }
    }
}

struct LocationPermissionRecoveryPrompt: Equatable, Identifiable {
    let state: LocationPermissionState
    let title: String
    let message: String
    let actions: [LocationPermissionRecoveryAction]

    var id: LocationPermissionState { state }

    static func make(for state: LocationPermissionState) -> LocationPermissionRecoveryPrompt? {
        switch state {
        case .denied:
            return .init(
                state: .denied,
                title: "Location Access Is Off",
                message: "Open Settings to re-enable current-location autofill, or continue placing memories without live location.",
                actions: [.openSettings, .continueWithoutLocation]
            )
        case .restricted:
            return .init(
                state: .restricted,
                title: "Location Access Is Restricted",
                message: "This device cannot grant location access right now. You can still continue and place memories without current-location autofill.",
                actions: [.continueWithoutLocation]
            )
        case .authorized, .notDetermined:
            return nil
        }
    }
}

enum CurrentLocationActionResult: Equatable {
    case requestSystemPermission
    case centerOnUser
    case showRecoveryPrompt
}

enum LocationPermissionRecoveryResult: Equatable {
    case openSettings
    case continueWithoutLocation
}

@MainActor
final class LocationPermissionStore: ObservableObject {
    @Published private(set) var permissionState: LocationPermissionState
    @Published private(set) var recoveryPrompt: LocationPermissionRecoveryPrompt?
    @Published private(set) var isUsingManualFallback = false

    private let currentStatus: () -> CLAuthorizationStatus
    private let requestWhenInUseAuthorization: () -> Void
    private let retainedLocationManager: CLLocationManager?

    convenience init() {
        let manager = CLLocationManager()
        self.init(
            currentStatus: { manager.authorizationStatus },
            requestWhenInUseAuthorization: { manager.requestWhenInUseAuthorization() },
            retainedLocationManager: manager
        )
    }

    init(
        currentStatus: @escaping () -> CLAuthorizationStatus,
        requestWhenInUseAuthorization: @escaping () -> Void,
        retainedLocationManager: CLLocationManager? = nil
    ) {
        self.currentStatus = currentStatus
        self.requestWhenInUseAuthorization = requestWhenInUseAuthorization
        self.retainedLocationManager = retainedLocationManager

        let initialState = LocationPermissionState(status: currentStatus())
        permissionState = initialState
        recoveryPrompt = LocationPermissionRecoveryPrompt.make(for: initialState)
    }

    func refresh() {
        permissionState = LocationPermissionState(status: currentStatus())
        recoveryPrompt = LocationPermissionRecoveryPrompt.make(for: permissionState)

        if permissionState == .authorized {
            isUsingManualFallback = false
        }
    }

    @discardableResult
    func handleCurrentLocationTap() -> CurrentLocationActionResult {
        refresh()

        switch permissionState {
        case .authorized:
            recoveryPrompt = nil
            isUsingManualFallback = false
            return .centerOnUser
        case .notDetermined:
            recoveryPrompt = nil
            isUsingManualFallback = false
            requestWhenInUseAuthorization()
            return .requestSystemPermission
        case .denied, .restricted:
            recoveryPrompt = LocationPermissionRecoveryPrompt.make(for: permissionState)
            return .showRecoveryPrompt
        }
    }

    func handleRecoveryAction(_ action: LocationPermissionRecoveryAction) -> LocationPermissionRecoveryResult {
        dismissRecoveryPrompt()

        switch action {
        case .openSettings:
            return .openSettings
        case .continueWithoutLocation:
            isUsingManualFallback = true
            return .continueWithoutLocation
        }
    }

    func dismissRecoveryPrompt() {
        recoveryPrompt = nil
    }
}
