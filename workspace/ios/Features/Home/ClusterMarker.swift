import CoreLocation
import SwiftUI

struct MemoryPinCluster: Identifiable, Hashable {
    let memories: [DBMemory]

    var id: UUID {
        representativeMemory.id
    }

    var representativeMemory: DBMemory {
        memories.first ?? MemoryMapPinStyle.emptyMemory
    }

    var coordinate: CLLocationCoordinate2D {
        representativeMemory.coordinate
    }

    var count: Int {
        memories.count
    }

    func contains(memoryID: UUID?) -> Bool {
        guard let memoryID else { return false }
        return memories.contains { $0.id == memoryID }
    }
}

extension Array where Element == DBMemory {
    /// Lightweight clustering for equal/near-equal coordinates.
    /// Real map zoom-aware clustering is deferred to a later MapKit algorithm.
    func clusteredByCoordinateRadius(_ radius: CLLocationDegrees = 0.0008) -> [MemoryPinCluster] {
        var clusters: [MemoryPinCluster] = []

        for memory in self {
            if let index = clusters.firstIndex(where: { cluster in
                cluster.coordinate.distance(to: memory.coordinate) <= radius
            }) {
                var mergedMemories = clusters[index].memories
                mergedMemories.append(memory)
                clusters[index] = MemoryPinCluster(memories: mergedMemories)
            } else {
                clusters.append(MemoryPinCluster(memories: [memory]))
            }
        }

        return clusters
    }
}

struct ClusterMarker: View {
    let cluster: MemoryPinCluster
    var isSelected: Bool = false
    var isDimmed: Bool = false

    var body: some View {
        VStack(spacing: UnfadingTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(MemoryMapPinStyle.color(for: cluster.representativeMemory).gradient)
                    .frame(width: 50, height: 50)

                Text("\(cluster.count)")
                    .font(UnfadingTheme.Font.metaNum(16, weight: .black))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .padding(.horizontal, UnfadingTheme.Spacing.sm)
                    .frame(minWidth: 34, minHeight: 28)
                    .background(UnfadingTheme.Color.textPrimary.opacity(0.16), in: Capsule())
            }
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(UnfadingTheme.Color.primary.opacity(0.38), lineWidth: 8)
                        .frame(width: 64, height: 64)
                }
            }
            .shadow(color: UnfadingTheme.Color.pinShadow, radius: 8, y: 4)

            Text(MemoryMapPinStyle.shortLabel(for: cluster.representativeMemory))
                .font(UnfadingTheme.Font.caption2Semibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .padding(.vertical, UnfadingTheme.Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .frame(minWidth: 64, minHeight: 74)
        .scaleEffect(isSelected ? 1.15 : 1)
        .opacity(isDimmed ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.22), value: isSelected)
        .animation(.easeInOut(duration: 0.22), value: isDimmed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(UnfadingLocalized.Home.clusterMarkerLabel(
            place: MemoryMapPinStyle.shortLabel(for: cluster.representativeMemory),
            count: cluster.count
        ))
    }
}

extension DBMemory {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: locationLat, longitude: locationLng)
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDegrees {
        max(abs(latitude - other.latitude), abs(longitude - other.longitude))
    }
}
