import SwiftUI

enum SheetTab: String, CaseIterable, Identifiable {
    case curation
    case archive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .curation: return "큐레이션"
        case .archive: return "보관함"
        }
    }
}

enum ArchiveSortOrder: String, CaseIterable, Identifiable {
    case latest
    case oldest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latest: return "최신순"
        case .oldest: return "오래된순"
        }
    }
}

struct SheetTabs: View {
    @Binding var selectedTab: SheetTab

    var body: some View {
        HStack(spacing: UnfadingTheme.Spacing.xs) {
            ForEach(SheetTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(UnfadingTheme.Font.sectionTitle(14))
                        .foregroundStyle(selectedTab == tab ? UnfadingTheme.Color.textPrimary : UnfadingTheme.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous)
                                    .fill(UnfadingTheme.Color.sheet)
                                    .shadow(color: UnfadingTheme.Color.shadow.opacity(1.4), radius: 6, x: 0, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel(tab.title)
                .accessibilityValue(selectedTab == tab ? "선택됨" : "")
            }
        }
        .padding(UnfadingTheme.Spacing.xs)
        .background(
            UnfadingTheme.Color.surface.opacity(0.72),
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-sheet-tabs")
    }
}

struct HomeSheetContent: View {
    @Binding var selectedTab: SheetTab
    let onRewindTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
            SheetTabs(selectedTab: $selectedTab)

            switch selectedTab {
            case .curation:
                SheetCuratedContent(onRewindTap: onRewindTap)
            case .archive:
                SheetArchiveContent()
            }
        }
        .padding(.horizontal, UnfadingTheme.Spacing.lg)
        .padding(.top, UnfadingTheme.Spacing.sm)
        .padding(.bottom, UnfadingTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SheetCuratedContent: View {
    let onRewindTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
            WeeklyCoverEventCard(event: SampleSheetData.weeklyEvent)

            EventStrip(events: SampleSheetData.monthlyEvents)

            PlaceBundleRow(bundles: SampleSheetData.placeBundles)

            RewindHintCard(onTap: onRewindTap)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-sheet-curation")
    }
}

struct WeeklyCoverEventCard: View {
    let event: SheetMemoryEvent

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text("이번 주")
                .font(UnfadingTheme.Font.sectionTitle())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            ZStack(alignment: .bottomLeading) {
                EventArtwork(symbols: event.photoSymbols, color: event.tint)
                    .frame(height: 172)
                    .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))

                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    Text(event.title)
                        .font(UnfadingTheme.Font.title3Bold())
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: UnfadingTheme.Spacing.xs) {
                        Label(event.place, systemImage: "mappin.and.ellipse")
                        Text("\(event.photoCount)장")
                    }
                    .font(UnfadingTheme.Font.footnoteSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .padding(.horizontal, UnfadingTheme.Spacing.sm)
                    .frame(minHeight: 32)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(UnfadingTheme.Spacing.lg)
            }
            .accessibilityLabel("\(event.title), \(event.place), 사진 \(event.photoCount)장")
        }
    }
}

struct EventStrip: View {
    let events: [SheetMemoryEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text("이달의 추억")
                .font(UnfadingTheme.Font.sectionTitle())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(events) { event in
                        EventStripPill(event: event)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .accessibilityIdentifier("home-event-strip")
    }
}

private struct EventStripPill: View {
    let event: SheetMemoryEvent

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            DateChip(date: event.date)

            Text(event.title)
                .font(UnfadingTheme.Font.sectionTitle(14))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Label(event.place, systemImage: "mappin")
                .font(UnfadingTheme.Font.tag(10.5))
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                .lineLimit(1)
        }
        .padding(UnfadingTheme.Spacing.md)
        .frame(width: 156, height: 132, alignment: .topLeading)
        .background(
            UnfadingTheme.Color.card,
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
        }
        .shadow(style: UnfadingTheme.Shadow.card)
        .accessibilityElement(children: .combine)
    }
}

struct PlaceBundleRow: View {
    let bundles: [PlaceBundle]

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text("장소 묶음")
                .font(UnfadingTheme.Font.sectionTitle())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            VStack(spacing: UnfadingTheme.Spacing.sm) {
                ForEach(bundles) { bundle in
                    HStack(spacing: UnfadingTheme.Spacing.md) {
                        ThreeUpThumbnail(symbols: bundle.photoSymbols, color: bundle.tint)
                            .frame(width: 96, height: 72)

                        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                            Text(bundle.place)
                                .font(UnfadingTheme.Font.sectionTitle(14.5))
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                                .lineLimit(1)
                            Text("\(bundle.visitCount)번 방문 · \(bundle.photoCount)장")
                                .font(UnfadingTheme.Font.footnote())
                                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        }

                        Spacer(minLength: UnfadingTheme.Spacing.sm)
                    }
                    .padding(UnfadingTheme.Spacing.sm)
                    .frame(minHeight: 88)
                    .background(
                        UnfadingTheme.Color.card,
                        in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                            .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
                    }
                }
            }
        }
        .accessibilityIdentifier("home-place-bundle-row")
    }
}

struct SheetArchiveContent: View {
    @State private var sortOrder: ArchiveSortOrder = .latest

    private var events: [SheetMemoryEvent] {
        SampleSheetData.archiveEvents.sortedEvents(order: sortOrder)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
            archiveHeader

            LazyVStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                ForEach(events) { event in
                    ArchiveEventSection(event: event)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-sheet-archive")
    }

    private var archiveHeader: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text("모든 추억 · \(SampleSheetData.archiveEvents.count)개 이벤트 · \(SampleSheetData.totalArchivePhotoCount)장")
                .font(UnfadingTheme.Font.sectionTitle(14.5))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            HStack(spacing: UnfadingTheme.Spacing.xs) {
                ForEach(ArchiveSortOrder.allCases) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        Text(order.title)
                            .font(UnfadingTheme.Font.footnoteSemibold())
                            .foregroundStyle(sortOrder == order ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.textSecondary)
                            .padding(.horizontal, UnfadingTheme.Spacing.md)
                            .frame(minHeight: 44)
                            .background(
                                sortOrder == order ? UnfadingTheme.Color.primary : UnfadingTheme.Color.surface,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(order.title)
                    .accessibilityValue(sortOrder == order ? "선택됨" : "")
                }
            }
        }
    }
}

struct ArchiveEventSection: View {
    let event: SheetMemoryEvent

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 3),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            HStack(alignment: .center, spacing: UnfadingTheme.Spacing.sm) {
                DateBadge(date: event.date)

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(UnfadingTheme.Font.sectionTitle(14.5))
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        .lineLimit(2)
                    Text("\(event.place) · \(event.photoCount)장")
                        .font(UnfadingTheme.Font.footnote())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(Array(event.photoSymbols.enumerated()), id: \.offset) { index, symbol in
                    ArchivePhotoTile(symbol: symbol, color: event.tint, count: index == 0 && event.photoCount > 1 ? event.photoCount : nil)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(event.place), 사진 \(event.photoCount)장")
    }
}

struct SheetMemoryEvent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let place: String
    let date: Date
    let photoCount: Int
    let photoSymbols: [String]
    let tintIndex: Int

    var tint: Color {
        UnfadingTheme.Color.memberPalette[tintIndex % UnfadingTheme.Color.memberPalette.count]
    }
}

struct PlaceBundle: Identifiable, Hashable {
    let id: UUID
    let place: String
    let visitCount: Int
    let photoCount: Int
    let photoSymbols: [String]
    let tintIndex: Int

    var tint: Color {
        UnfadingTheme.Color.memberPalette[tintIndex % UnfadingTheme.Color.memberPalette.count]
    }
}

enum SampleSheetData {
    static let weeklyEvent = archiveEvents[0]

    static let monthlyEvents: [SheetMemoryEvent] = Array(archiveEvents.prefix(4))

    static let archiveEvents: [SheetMemoryEvent] = [
        .init(
            id: UUID(uuidString: "a1000001-1111-4111-8111-111111111111")!,
            title: "상수 루프톱 저녁",
            place: "상수 루프톱",
            date: makeDate(year: 2026, month: 4, day: 21),
            photoCount: 6,
            photoSymbols: ["fork.knife", "wineglass", "camera.fill", "heart.fill", "sparkles", "person.3.fill"],
            tintIndex: 0
        ),
        .init(
            id: UUID(uuidString: "a1000002-2222-4222-8222-222222222222")!,
            title: "한강 노을 라이딩",
            place: "여의도 한강공원",
            date: makeDate(year: 2026, month: 4, day: 18),
            photoCount: 5,
            photoSymbols: ["bicycle", "sunset.fill", "figure.outdoor.cycle", "water.waves", "camera.fill"],
            tintIndex: 3
        ),
        .init(
            id: UUID(uuidString: "a1000003-3333-4333-8333-333333333333")!,
            title: "아침 산책",
            place: "서울 도심 산책로",
            date: makeDate(year: 2026, month: 4, day: 9),
            photoCount: 4,
            photoSymbols: ["sunrise.fill", "leaf.fill", "figure.walk", "mappin"],
            tintIndex: 1
        ),
        .init(
            id: UUID(uuidString: "a1000004-4444-4444-8444-444444444444")!,
            title: "늦은 카페 회의",
            place: "연남 작은 카페",
            date: makeDate(year: 2026, month: 3, day: 28),
            photoCount: 3,
            photoSymbols: ["cup.and.saucer.fill", "book.closed.fill", "camera.fill"],
            tintIndex: 7
        )
    ]

    static let placeBundles: [PlaceBundle] = [
        .init(
            id: UUID(uuidString: "b1000001-1111-4111-8111-111111111111")!,
            place: "상수 루프톱",
            visitCount: 4,
            photoCount: 18,
            photoSymbols: ["fork.knife", "wineglass", "sparkles"],
            tintIndex: 0
        ),
        .init(
            id: UUID(uuidString: "b1000002-2222-4222-8222-222222222222")!,
            place: "여의도 한강공원",
            visitCount: 3,
            photoCount: 14,
            photoSymbols: ["bicycle", "sunset.fill", "water.waves"],
            tintIndex: 3
        )
    ]

    static var totalArchivePhotoCount: Int {
        archiveEvents.reduce(0) { $0 + $1.photoCount }
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}

extension Array where Element == SheetMemoryEvent {
    func sortedEvents(order: ArchiveSortOrder) -> [SheetMemoryEvent] {
        sorted {
            switch order {
            case .latest: return $0.date > $1.date
            case .oldest: return $0.date < $1.date
            }
        }
    }
}

private struct EventArtwork: View {
    let symbols: [String]
    let color: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [color.opacity(0.82), UnfadingTheme.Color.secondary.opacity(0.58), UnfadingTheme.Color.primary.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: UnfadingTheme.Spacing.lg) {
                ForEach(Array(symbols.prefix(3).enumerated()), id: \.offset) { _, symbol in
                    Image(systemName: symbol)
                        .font(.title)
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary.opacity(0.86))
                        .frame(width: 58, height: 58)
                        .background(UnfadingTheme.Color.textOnPrimary.opacity(0.14), in: Circle())
                }
            }
            .accessibilityHidden(true)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "photo.on.rectangle.angled")
                .imageScale(.medium)
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary.opacity(0.78))
                .padding(UnfadingTheme.Spacing.md)
        }
    }
}

private struct ThreeUpThumbnail: View {
    let symbols: [String]
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(symbols.prefix(3).enumerated()), id: \.offset) { _, symbol in
                ArchivePhotoTile(symbol: symbol, color: color, count: nil)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous))
        .accessibilityHidden(true)
    }
}

private struct ArchivePhotoTile: View {
    let symbol: String
    let color: Color
    let count: Int?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            color.opacity(0.24)

            diagonalStripeOverlay

            Image(systemName: symbol)
                .imageScale(.large)
                .foregroundStyle(color)

            if let count {
                Text("\(count)")
                    .font(UnfadingTheme.Font.metaNum(10, weight: .black))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .padding(.horizontal, UnfadingTheme.Spacing.xs)
                    .frame(minHeight: 24)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var diagonalStripeOverlay: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, proxy.size.height)
            HStack(spacing: 9) {
                ForEach(0..<8, id: \.self) { _ in
                    Rectangle()
                        .fill(UnfadingTheme.Color.textOnPrimary.opacity(0.12))
                        .frame(width: 3, height: width * 1.8)
                }
            }
            .rotationEffect(.degrees(35))
            .offset(x: -width * 0.45, y: -width * 0.3)
        }
        .allowsHitTesting(false)
    }
}

private struct DateChip: View {
    let date: Date

    var body: some View {
        Text(dayText)
            .font(UnfadingTheme.Font.metaNum(11, weight: .black))
            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.sm)
            .frame(minHeight: 28)
            .background(UnfadingTheme.Color.primary, in: Capsule())
    }

    private var dayText: String {
        "\(Calendar.current.component(.day, from: date))일"
    }
}

private struct DateBadge: View {
    let date: Date

    var body: some View {
        VStack(spacing: 1) {
            Text("\(Calendar.current.component(.month, from: date))월")
                .font(UnfadingTheme.Font.metaNum(8.5, weight: .black))
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            Text("\(Calendar.current.component(.day, from: date))")
                .font(UnfadingTheme.Font.sectionTitle(15))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
        }
        .frame(width: 44, height: 44)
        .background(UnfadingTheme.Color.surface, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous))
        .accessibilityLabel("\(Calendar.current.component(.month, from: date))월 \(Calendar.current.component(.day, from: date))일")
    }
}
