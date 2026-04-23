import SwiftUI

struct SheetFilteredHeader: View {
    let cluster: MemoryPinCluster
    let memoryCount: Int
    let eventDate: Date
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            HStack(alignment: .center, spacing: UnfadingTheme.Spacing.sm) {
                pinBadge

                VStack(alignment: .leading, spacing: 3) {
                    Text(placeTitle)
                        .font(UnfadingTheme.Font.sectionTitle(16))
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        .lineLimit(1)

                    Text("이 장소에서 \(memoryCount)개의 추억")
                        .font(UnfadingTheme.Font.footnote())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: UnfadingTheme.Spacing.sm)

                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .imageScale(.small)
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(UnfadingTheme.Color.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(UnfadingLocalized.Accessibility.clearSelectionLabel)
                .accessibilityHint(UnfadingLocalized.Accessibility.clearSelectionHint)
            }

            Text(Self.eventFormatter.string(from: eventDate))
                .font(UnfadingTheme.Font.metaNum(11, weight: .black))
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .frame(minHeight: 30)
                .background(UnfadingTheme.Color.primary, in: Capsule())
                .accessibilityLabel(Self.accessibilityFormatter.string(from: eventDate))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet-filtered-header")
    }

    private var pinBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: MemoryMapPinStyle.symbol(for: cluster.representativeMemory))
                .imageScale(.medium)
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: 44, height: 44)
                .background(MemoryMapPinStyle.color(for: cluster.representativeMemory), in: Circle())

            if cluster.count > 1 {
                Text("\(cluster.count)")
                    .font(UnfadingTheme.Font.metaNum(9, weight: .black))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(UnfadingTheme.Color.textPrimary, in: Circle())
                    .offset(x: 4, y: -4)
            }
        }
        .accessibilityHidden(true)
    }

    private var placeTitle: String {
        if cluster.count > 1 {
            return "\(MemoryMapPinStyle.shortLabel(for: cluster.representativeMemory)) 장소 묶음"
        }
        return cluster.representativeMemory.placeTitle
    }

    private static let eventFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}

struct SheetFilteredContent: View {
    let cluster: MemoryPinCluster
    let onClear: () -> Void

    private var items: [MemoryRowCardModel] {
        MemoryRowCardModel.realItems(for: cluster.memories)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
            SheetFilteredHeader(
                cluster: cluster,
                memoryCount: items.count,
                eventDate: eventDate,
                onClear: onClear
            )

            if items.isEmpty {
                emptyState
            } else {
                LazyVStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(items) { item in
                        MemoryRowCard(item: item)
                    }
                }
            }
        }
        .padding(.horizontal, UnfadingTheme.Spacing.lg)
        .padding(.top, UnfadingTheme.Spacing.sm)
        .padding(.bottom, UnfadingTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("sheet-filtered-content")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text("이 장소의 첫 추억을 남겨보세요")
                .font(UnfadingTheme.Font.sectionTitle(15))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(UnfadingTheme.Spacing.lg)
                .background(
                    UnfadingTheme.Color.card,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                        .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
                }

            Button {
                // Composer location seeding is handled in a later real-data round.
            } label: {
                Label("+ 이 장소에 추억 추가", systemImage: "plus")
                    .font(UnfadingTheme.Font.sectionTitle(14))
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay {
                        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                            .stroke(
                                UnfadingTheme.Color.primary.opacity(0.66),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                            )
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Accessibility.addMemoryAtPlaceLabel)
        }
    }

    private var eventDate: Date {
        cluster.representativeMemory.date
    }
}
