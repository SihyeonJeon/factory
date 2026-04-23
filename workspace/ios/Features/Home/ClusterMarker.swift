import CoreLocation
import SwiftUI

struct MemoryPinCluster: Identifiable, Hashable {
    let pins: [SampleMemoryPin]

    var id: UUID {
        representativePin.id
    }

    var representativePin: SampleMemoryPin {
        pins.first ?? SampleMemoryPin.samples[0]
    }

    var coordinate: CLLocationCoordinate2D {
        representativePin.coordinate
    }

    var count: Int {
        pins.count
    }

    func contains(pinID: UUID?) -> Bool {
        guard let pinID else { return false }
        return pins.contains { $0.id == pinID }
    }
}

extension Array where Element == SampleMemoryPin {
    /// Lightweight sample-data clustering for equal/near-equal coordinates.
    /// Real map zoom-aware clustering is deferred to a later MapKit algorithm.
    func clusteredByCoordinateRadius(_ radius: CLLocationDegrees = 0.0008) -> [MemoryPinCluster] {
        var clusters: [MemoryPinCluster] = []

        for pin in self {
            if let index = clusters.firstIndex(where: { cluster in
                cluster.coordinate.distance(to: pin.coordinate) <= radius
            }) {
                var mergedPins = clusters[index].pins
                mergedPins.append(pin)
                clusters[index] = MemoryPinCluster(pins: mergedPins)
            } else {
                clusters.append(MemoryPinCluster(pins: [pin]))
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
                    .fill(cluster.representativePin.color.gradient)
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

            Text(cluster.representativePin.shortLabel)
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
        .accessibilityLabel("\(cluster.representativePin.shortLabel), 추억 \(cluster.count)개")
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDegrees {
        max(abs(latitude - other.latitude), abs(longitude - other.longitude))
    }
}
