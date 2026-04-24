import CoreLocation
import MapKit

struct ClusterItem: Identifiable, Hashable {
    let memories: [DBMemory]
    let coordinate: CLLocationCoordinate2D

    var id: String {
        memories
            .map(\.id.uuidString)
            .sorted()
            .joined(separator: "|")
    }

    static func == (lhs: ClusterItem, rhs: ClusterItem) -> Bool {
        lhs.id == rhs.id
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }

    var representativeMemory: DBMemory {
        memories.first ?? MemoryMapPinStyle.emptyMemory
    }

    var count: Int {
        memories.count
    }

    var isCluster: Bool {
        count > 1
    }

    var selectionID: String {
        id
    }

    var accessibilityIdentifier: String {
        if isCluster {
            return "memory-cluster-\(count)-\(representativeMemory.id.uuidString)"
        }
        return "memory-pin-\(representativeMemory.id.uuidString)"
    }

    func contains(memoryID: UUID?) -> Bool {
        guard let memoryID else { return false }
        return memories.contains { $0.id == memoryID }
    }

    func focusRegion(paddingMultiplier: CLLocationDistance = 1.8) -> MKCoordinateRegion {
        guard isCluster else {
            return MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 220,
                longitudinalMeters: 220
            )
        }

        let latitudes = memories.map(\.locationLat)
        let longitudes = memories.map(\.locationLng)
        let minCoordinate = CLLocationCoordinate2D(
            latitude: latitudes.min() ?? coordinate.latitude,
            longitude: longitudes.min() ?? coordinate.longitude
        )
        let maxCoordinate = CLLocationCoordinate2D(
            latitude: latitudes.max() ?? coordinate.latitude,
            longitude: longitudes.max() ?? coordinate.longitude
        )

        let verticalMeters = max(
            CLLocation(latitude: minCoordinate.latitude, longitude: coordinate.longitude)
                .distance(from: CLLocation(latitude: maxCoordinate.latitude, longitude: coordinate.longitude)),
            180
        )
        let horizontalMeters = max(
            CLLocation(latitude: coordinate.latitude, longitude: minCoordinate.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: maxCoordinate.longitude)),
            180
        )

        return MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: verticalMeters * paddingMultiplier,
            longitudinalMeters: horizontalMeters * paddingMultiplier
        )
    }
}

struct MemoryClusterizer {
    let minimumRadiusMeters: CLLocationDistance
    let maximumRadiusMeters: CLLocationDistance
    let viewportScaleFactor: Double

    init(
        minimumRadiusMeters: CLLocationDistance = 50,
        maximumRadiusMeters: CLLocationDistance = 320,
        viewportScaleFactor: Double = 0.035
    ) {
        self.minimumRadiusMeters = minimumRadiusMeters
        self.maximumRadiusMeters = maximumRadiusMeters
        self.viewportScaleFactor = viewportScaleFactor
    }

    func clusterItems(
        for memories: [DBMemory],
        in region: MKCoordinateRegion,
        radiusOverride: CLLocationDistance? = nil
    ) -> [ClusterItem] {
        guard memories.isEmpty == false else { return [] }

        let sortedMemories = memories.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        let radiusMeters = radiusOverride ?? radius(for: region)
        var visited = Set<UUID>()
        var items: [ClusterItem] = []

        for seed in sortedMemories {
            guard visited.insert(seed.id).inserted else { continue }

            var component: [DBMemory] = []
            var queue = [seed]

            while let current = queue.popLast() {
                component.append(current)

                for candidate in sortedMemories {
                    guard visited.contains(candidate.id) == false else { continue }
                    guard current.coordinate.distance(to: candidate.coordinate) <= radiusMeters else { continue }
                    visited.insert(candidate.id)
                    queue.append(candidate)
                }
            }

            items.append(
                ClusterItem(
                    memories: component.sorted { lhs, rhs in
                        if lhs.date != rhs.date { return lhs.date > rhs.date }
                        return lhs.id.uuidString < rhs.id.uuidString
                    },
                    coordinate: Self.centroid(for: component)
                )
            )
        }

        return items.sorted { lhs, rhs in
            if lhs.isCluster != rhs.isCluster { return lhs.isCluster && !rhs.isCluster }
            if lhs.representativeMemory.date != rhs.representativeMemory.date {
                return lhs.representativeMemory.date > rhs.representativeMemory.date
            }
            return lhs.id < rhs.id
        }
    }

    func radius(for region: MKCoordinateRegion) -> CLLocationDistance {
        let shorterEdge = region.shorterEdgeMeters
        let scaledRadius = shorterEdge * viewportScaleFactor
        return min(max(scaledRadius, minimumRadiusMeters), maximumRadiusMeters)
    }

    private static func centroid(for memories: [DBMemory]) -> CLLocationCoordinate2D {
        guard memories.isEmpty == false else {
            return MemoryMapPinStyle.emptyMemory.coordinate
        }

        let latitude = memories.map(\.locationLat).reduce(0, +) / Double(memories.count)
        let longitude = memories.map(\.locationLng).reduce(0, +) / Double(memories.count)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension DBMemory {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: locationLat, longitude: locationLng)
    }
}

private extension MKCoordinateRegion {
    var shorterEdgeMeters: CLLocationDistance {
        let north = center.latitude + (span.latitudeDelta / 2)
        let south = center.latitude - (span.latitudeDelta / 2)
        let east = center.longitude + (span.longitudeDelta / 2)
        let west = center.longitude - (span.longitudeDelta / 2)

        let vertical = CLLocation(latitude: north, longitude: center.longitude)
            .distance(from: CLLocation(latitude: south, longitude: center.longitude))
        let horizontal = CLLocation(latitude: center.latitude, longitude: east)
            .distance(from: CLLocation(latitude: center.latitude, longitude: west))
        return max(min(vertical, horizontal), 1)
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
