import Foundation
import WidgetKit

struct TodayMemoryEntry: TimelineEntry, Equatable {
    let date: Date
    let memory: TodayMemorySample
    let isPlaceholder: Bool

    var deepLinkURL: URL {
        URL(string: "unfading://memory/\(memory.id.uuidString)")!
    }
}

struct TodayMemorySample: Identifiable, Equatable {
    enum ArtworkStyle: String, Equatable {
        case peachBlossom
        case mintSunrise
        case duskLavender
    }

    let id: UUID
    let title: String
    let place: String
    let date: Date
    let coverAssetName: String?
    let artworkStyle: ArtworkStyle
}

struct TodayMemoryProvider: TimelineProvider {
    private var calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
        self.calendar.locale = Locale(identifier: "ko_KR")
        self.calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
    }

    func placeholder(in context: Context) -> TodayMemoryEntry {
        placeholderEntry(referenceDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayMemoryEntry) -> Void) {
        completion(snapshotEntry(referenceDate: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayMemoryEntry>) -> Void) {
        completion(timeline(referenceDate: Date()))
    }

    func placeholderEntry(referenceDate: Date) -> TodayMemoryEntry {
        TodayMemoryEntry(
            date: referenceDate,
            memory: Self.sampleMemories(referenceDate: referenceDate, calendar: calendar).last ?? Self.fallbackSample(referenceDate: referenceDate),
            isPlaceholder: true
        )
    }

    func snapshotEntry(referenceDate: Date) -> TodayMemoryEntry {
        TodayMemoryEntry(
            date: referenceDate,
            memory: currentMemory(referenceDate: referenceDate),
            isPlaceholder: false
        )
    }

    func timeline(referenceDate: Date) -> Timeline<TodayMemoryEntry> {
        let entry = snapshotEntry(referenceDate: referenceDate)
        let refreshDate = nextRefreshDate(after: referenceDate)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    func currentMemory(referenceDate: Date) -> TodayMemorySample {
        let samples = Self.sampleMemories(referenceDate: referenceDate, calendar: calendar)
        let todaysSamples = samples.filter { calendar.isDate($0.date, inSameDayAs: referenceDate) }
        return todaysSamples.max(by: { $0.date < $1.date }) ?? samples.max(by: { $0.date < $1.date }) ?? Self.fallbackSample(referenceDate: referenceDate)
    }

    func nextRefreshDate(after referenceDate: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? referenceDate.addingTimeInterval(60 * 60 * 6)
    }

    static func sampleMemories(referenceDate: Date, calendar: Calendar) -> [TodayMemorySample] {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        return [
            TodayMemorySample(
                id: UUID(uuidString: "eeeeeee1-eeee-4eee-8eee-eeeeeeeeeee1")!,
                title: "상수 루프톱 저녁",
                place: "상수 루프톱",
                date: calendar.date(byAdding: .hour, value: 9, to: startOfDay) ?? referenceDate,
                coverAssetName: nil,
                artworkStyle: .peachBlossom
            ),
            TodayMemorySample(
                id: UUID(uuidString: "eeeeeee2-eeee-4eee-8eee-eeeeeeeeeee2")!,
                title: "한강 산책",
                place: "여의도 한강공원",
                date: calendar.date(byAdding: .hour, value: 20, to: startOfDay) ?? referenceDate,
                coverAssetName: nil,
                artworkStyle: .mintSunrise
            ),
            TodayMemorySample(
                id: UUID(uuidString: "eeeeeee3-eeee-4eee-8eee-eeeeeeeeeee3")!,
                title: "해돋이 산책",
                place: "광화문",
                date: calendar.date(byAdding: .day, value: -2, to: startOfDay) ?? referenceDate,
                coverAssetName: nil,
                artworkStyle: .duskLavender
            )
        ]
    }

    static func fallbackSample(referenceDate: Date) -> TodayMemorySample {
        TodayMemorySample(
            id: UUID(uuidString: "eeeeeee9-eeee-4eee-8eee-eeeeeeeeeee9")!,
            title: "오늘의 추억",
            place: "함께 남긴 장소",
            date: referenceDate,
            coverAssetName: nil,
            artworkStyle: .peachBlossom
        )
    }
}
