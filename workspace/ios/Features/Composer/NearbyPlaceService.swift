import CoreLocation
import Foundation
import MapKit

struct PickedPlace: Equatable {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String?

    static func == (lhs: PickedPlace, rhs: PickedPlace) -> Bool {
        lhs.name == rhs.name
            && lhs.address == rhs.address
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct DiscoveredPlace: Hashable, Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Double?
    let category: MKPointOfInterestCategory?
    let address: String?

    init(
        id: String,
        name: String,
        coordinate: CLLocationCoordinate2D,
        distanceMeters: Double?,
        category: MKPointOfInterestCategory?,
        address: String? = nil
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.distanceMeters = distanceMeters
        self.category = category
        self.address = address
    }

    static func == (lhs: DiscoveredPlace, rhs: DiscoveredPlace) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.distanceMeters == rhs.distanceMeters
            && lhs.category == rhs.category
            && lhs.address == rhs.address
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(distanceMeters)
        hasher.combine(category?.rawValue)
        hasher.combine(address)
    }

    var pickedPlace: PickedPlace {
        PickedPlace(name: name, coordinate: coordinate, address: address)
    }
}

protocol PlaceResolving: Sendable {
    func searchByName(_ query: String, near: CLLocationCoordinate2D?) async throws -> [DiscoveredPlace]
    func nearby(_ center: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [DiscoveredPlace]
    func closestMatch(to coord: CLLocationCoordinate2D) async throws -> DiscoveredPlace?
}

actor NearbyPlaceService: PlaceResolving {
    private let geocoder = CLGeocoder()

    func searchByName(_ query: String, near: CLLocationCoordinate2D?) async throws -> [DiscoveredPlace] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let near {
            request.region = MKCoordinateRegion(
                center: near,
                latitudinalMeters: 1_000,
                longitudinalMeters: 1_000
            )
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems
            .map { mapItem in
                Self.place(from: mapItem, reference: near)
            }
            .sorted(by: Self.sortPlaces)
    }

    func nearby(_ center: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [DiscoveredPlace] {
        let request = MKLocalPointsOfInterestRequest(
            center: center,
            radius: max(50, min(radiusMeters, 10_000))
        )
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems
            .map { mapItem in
                Self.place(from: mapItem, reference: center)
            }
            .sorted(by: Self.sortPlaces)
    }

    func closestMatch(to coord: CLLocationCoordinate2D) async throws -> DiscoveredPlace? {
        if let first = try? await nearby(coord, radiusMeters: 250).min(by: Self.sortPlaces) {
            return first
        }

        let placemarks = try await geocoder.reverseGeocodeLocation(
            CLLocation(latitude: coord.latitude, longitude: coord.longitude),
            preferredLocale: Locale(identifier: "ko_KR")
        )
        guard let placemark = placemarks.first else { return nil }
        let name = placemark.name ?? placemark.locality ?? UnfadingLocalized.Composer.placeholderCurrent

        return DiscoveredPlace(
            id: "reverse-\(coord.latitude)-\(coord.longitude)",
            name: name,
            coordinate: coord,
            distanceMeters: 0,
            category: nil,
            address: Self.address(from: placemark)
        )
    }

    static func address(from placemark: CLPlacemark) -> String? {
        [placemark.administrativeArea, placemark.locality, placemark.thoroughfare]
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed?.isEmpty == false ? trimmed : nil
            }
            .removingDuplicates()
            .joined(separator: " ")
            .nilIfEmpty
    }

    private static func place(from mapItem: MKMapItem, reference: CLLocationCoordinate2D?) -> DiscoveredPlace {
        let coordinate = mapItem.placemark.coordinate
        let distance = reference.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
        let id = [
            mapItem.name,
            String(format: "%.6f", coordinate.latitude),
            String(format: "%.6f", coordinate.longitude)
        ]
            .compactMap { $0 }
            .joined(separator: "|")

        return DiscoveredPlace(
            id: id,
            name: mapItem.name ?? mapItem.placemark.name ?? UnfadingLocalized.Composer.placeholderCurrent,
            coordinate: coordinate,
            distanceMeters: distance,
            category: mapItem.pointOfInterestCategory,
            address: address(from: mapItem.placemark)
        )
    }

    private static func sortPlaces(_ lhs: DiscoveredPlace, _ rhs: DiscoveredPlace) -> Bool {
        switch (lhs.distanceMeters, rhs.distanceMeters) {
        case let (lhs?, rhs?):
            return lhs < rhs
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.name < rhs.name
        }
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
