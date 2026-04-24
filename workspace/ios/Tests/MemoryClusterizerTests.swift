import CoreLocation
import MapKit
import XCTest
@testable import MemoryMap

final class MemoryClusterizerTests: XCTestCase {
    func test_clusters_points_within_radius_into_single_cluster() {
        let clusterizer = MemoryClusterizer()
        let items = clusterizer.clusterItems(
            for: [
                Self.memory(id: "00000000-0000-4000-8000-000000000101", latitude: 37.566500, longitude: 126.978000),
                Self.memory(id: "00000000-0000-4000-8000-000000000102", latitude: 37.566820, longitude: 126.978020),
                Self.memory(id: "00000000-0000-4000-8000-000000000103", latitude: 37.566720, longitude: 126.978280)
            ],
            in: Self.region,
            radiusOverride: 55
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.count, 3)
        XCTAssertTrue(items.first?.isCluster == true)
    }

    func test_larger_radius_merges_items_that_stay_separate_at_smaller_radius() {
        let memories = [
            Self.memory(id: "00000000-0000-4000-8000-000000000201", latitude: 37.566500, longitude: 126.978000),
            Self.memory(id: "00000000-0000-4000-8000-000000000202", latitude: 37.566980, longitude: 126.978000),
            Self.memory(id: "00000000-0000-4000-8000-000000000203", latitude: 37.568000, longitude: 126.978000)
        ]
        let clusterizer = MemoryClusterizer()

        let tightItems = clusterizer.clusterItems(for: memories, in: Self.region, radiusOverride: 50)
        let wideItems = clusterizer.clusterItems(for: memories, in: Self.region, radiusOverride: 170)

        XCTAssertEqual(tightItems.map(\.count).sorted(), [1, 1, 1])
        XCTAssertEqual(wideItems.count, 1)
        XCTAssertEqual(wideItems.first?.count, 3)
    }

    func test_single_memory_passes_through_without_cluster_shell() {
        let memory = Self.memory(
            id: "00000000-0000-4000-8000-000000000301",
            title: "광화문 산책",
            latitude: 37.5700,
            longitude: 126.9768
        )
        let item = MemoryClusterizer().clusterItems(for: [memory], in: Self.region).first

        XCTAssertEqual(item?.count, 1)
        XCTAssertFalse(item?.isCluster ?? true)
        XCTAssertEqual(item?.representativeMemory.id, memory.id)
        XCTAssertEqual(item?.coordinate.latitude ?? 0, memory.locationLat, accuracy: 0.000001)
        XCTAssertEqual(item?.coordinate.longitude ?? 0, memory.locationLng, accuracy: 0.000001)
    }

    private static let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        latitudinalMeters: 600,
        longitudinalMeters: 600
    )

    private static func memory(
        id: String,
        title: String = "추억",
        latitude: Double,
        longitude: Double
    ) -> DBMemory {
        DBMemory(
            id: UUID(uuidString: id)!,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            title: title,
            note: "노트",
            placeTitle: title,
            address: "서울",
            locationLat: latitude,
            locationLng: longitude,
            date: Date(timeIntervalSince1970: 1_777_000_000),
            capturedAt: nil,
            photoURL: nil,
            photoURLs: [],
            categories: ["food"],
            emotions: ["joy"],
            reactionCount: 1,
            createdAt: Date(timeIntervalSince1970: 1_777_000_000)
        )
    }
}
