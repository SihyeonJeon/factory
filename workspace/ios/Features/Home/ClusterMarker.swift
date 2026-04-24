import SwiftUI

struct ClusterMarker: View {
    let cluster: ClusterItem
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
