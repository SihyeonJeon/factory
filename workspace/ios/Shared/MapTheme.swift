import MapKit
import SwiftUI

enum MapTheme: String, CaseIterable, Codable, Hashable, Sendable {
    case default_ = "default"
    case warm
    case mono

    var title: String {
        switch self {
        case .default_:
            return UnfadingLocalized.MapTheme.defaultTitle
        case .warm:
            return UnfadingLocalized.MapTheme.warmTitle
        case .mono:
            return UnfadingLocalized.MapTheme.monoTitle
        }
    }

    var description: String {
        switch self {
        case .default_:
            return UnfadingLocalized.MapTheme.defaultDescription
        case .warm:
            return UnfadingLocalized.MapTheme.warmDescription
        case .mono:
            return UnfadingLocalized.MapTheme.monoDescription
        }
    }

    var style: MapStyle {
        switch self {
        case .default_:
            return .standard(elevation: .flat)
        case .warm:
            return .standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false)
        case .mono:
            return .hybrid(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false)
        }
    }

    var mapConfiguration: MKMapConfiguration? {
        switch self {
        case .default_:
            return nil
        case .warm:
            let configuration = MKStandardMapConfiguration(elevationStyle: .flat)
            configuration.pointOfInterestFilter = .excludingAll
            configuration.showsTraffic = false
            return configuration
        case .mono:
            let configuration = MKStandardMapConfiguration(emphasisStyle: .muted)
            configuration.pointOfInterestFilter = .excludingAll
            configuration.showsTraffic = false
            return configuration
        }
    }
}
