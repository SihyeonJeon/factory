import Foundation

// vibe-limit-checked: 11 sample aggregation only; real Supabase query is R38
struct RewindData: Equatable {
    let period: DateInterval
    let periodTitle: String
    let headline: String
    let topPlaces: [TopPlace]
    let firstVisitPlaces: [FirstVisitPlace]
    let photoHeavyDay: PhotoHeavyDay?
    let emotionTags: [EmotionTag]
    let totalMinutesTogether: Int

    var totalHoursTogether: Int {
        max(1, Int((Double(totalMinutesTogether) / 60.0).rounded()))
    }

    static func sample(for period: DateInterval) -> RewindData {
        make(from: sampleRecords(in: period), period: period)
    }

    static func make(from records: [RewindMemoryRecord], period: DateInterval) -> RewindData {
        let inPeriod = records.filter { period.contains($0.date) }
        let calendar = Calendar.current

        let topPlaces = Dictionary(grouping: inPeriod, by: \.placeTitle)
            .map { place, placeRecords in
                TopPlace(
                    title: place,
                    visitCount: placeRecords.count,
                    symbolName: placeRecords.first?.symbolName ?? "mappin"
                )
            }
            .sorted {
                if $0.visitCount == $1.visitCount { return $0.title < $1.title }
                return $0.visitCount > $1.visitCount
            }
            .prefix(3)

        let firstVisitPlaces = Dictionary(grouping: records, by: \.placeTitle)
            .compactMap { place, placeRecords -> FirstVisitPlace? in
                guard let first = placeRecords.min(by: { $0.date < $1.date }), period.contains(first.date) else {
                    return nil
                }
                return FirstVisitPlace(title: place, date: first.date, symbolName: first.symbolName)
            }
            .sorted { $0.date < $1.date }
            .prefix(9)

        let photoHeavyDay = Dictionary(grouping: inPeriod, by: { calendar.startOfDay(for: $0.date) })
            .map { date, dayRecords in
                PhotoHeavyDay(
                    date: date,
                    photoCount: dayRecords.reduce(0) { $0 + $1.photoCount },
                    symbolName: dayRecords.max(by: { $0.photoCount < $1.photoCount })?.symbolName ?? "photo"
                )
            }
            .filter { $0.photoCount > 0 }
            .sorted {
                if $0.photoCount == $1.photoCount { return $0.date < $1.date }
                return $0.photoCount > $1.photoCount
            }
            .first

        let emotionCounts = inPeriod
            .flatMap(\.emotionIDs)
            .reduce(into: [String: Int]()) { counts, emotion in
                counts[emotion, default: 0] += 1
            }
        let totalEmotionCount = max(1, emotionCounts.values.reduce(0, +))
        let emotionTags = emotionCounts
            .map { id, count in
                EmotionTag(
                    id: id,
                    title: UnfadingLocalized.draftTag(id: id, fallback: id),
                    ratio: Double(count) / Double(totalEmotionCount)
                )
            }
            .sorted { $0.ratio > $1.ratio }

        return RewindData(
            period: period,
            periodTitle: Self.periodTitle(for: period),
            headline: UnfadingLocalized.Rewind.coverHeadline,
            topPlaces: Array(topPlaces),
            firstVisitPlaces: Array(firstVisitPlaces),
            photoHeavyDay: photoHeavyDay,
            emotionTags: emotionTags,
            totalMinutesTogether: inPeriod.reduce(0) { $0 + $1.durationMinutes }
        )
    }

    private static func sampleRecords(in period: DateInterval) -> [RewindMemoryRecord] {
        let calendar = Calendar.current
        let start = period.start
        let pins = SampleMemoryPin.samples

        return [
            record(pin: pins[0], detailIndex: 0, date: calendar.date(byAdding: .day, value: 1, to: start) ?? start, photos: 6, minutes: 190),
            record(pin: pins[0], detailIndex: 0, date: calendar.date(byAdding: .day, value: 8, to: start) ?? start, photos: 3, minutes: 120),
            record(pin: pins[0], detailIndex: 0, date: calendar.date(byAdding: .day, value: 18, to: start) ?? start, photos: 2, minutes: 95),
            record(pin: pins[1], detailIndex: 1, date: calendar.date(byAdding: .day, value: 3, to: start) ?? start, photos: 4, minutes: 150),
            record(pin: pins[1], detailIndex: 1, date: calendar.date(byAdding: .day, value: 16, to: start) ?? start, photos: 8, minutes: 180),
            record(pin: pins[2], detailIndex: 2, date: calendar.date(byAdding: .day, value: 11, to: start) ?? start, photos: 5, minutes: 105)
        ]
    }

    private static func record(
        pin: SampleMemoryPin,
        detailIndex: Int,
        date: Date,
        photos: Int,
        minutes: Int
    ) -> RewindMemoryRecord {
        let detail = SampleMemoryDetail.samples[detailIndex]
        return RewindMemoryRecord(
            placeTitle: pin.title,
            date: date,
            photoCount: photos,
            symbolName: detail.photoPlaceholders.first ?? pin.symbol,
            emotionIDs: detail.moodTagIDs,
            durationMinutes: minutes
        )
    }

    private static func periodTitle(for period: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        let displayEnd = Calendar.current.date(byAdding: .second, value: -1, to: period.end) ?? period.end
        return "\(formatter.string(from: period.start)) - \(formatter.string(from: displayEnd))"
    }
}

struct RewindMemoryRecord: Equatable {
    let placeTitle: String
    let date: Date
    let photoCount: Int
    let symbolName: String
    let emotionIDs: [String]
    let durationMinutes: Int
}

struct TopPlace: Equatable, Identifiable {
    var id: String { title }
    let title: String
    let visitCount: Int
    let symbolName: String
}

struct FirstVisitPlace: Equatable, Identifiable {
    var id: String { title }
    let title: String
    let date: Date
    let symbolName: String
}

struct PhotoHeavyDay: Equatable {
    let date: Date
    let photoCount: Int
    let symbolName: String
}

struct EmotionTag: Equatable, Identifiable {
    var id: String
    let title: String
    let ratio: Double
}

enum RewindStoryKind: Int, CaseIterable, Identifiable {
    case cover
    case topPlaces
    case firstVisits
    case photoDay
    case emotionCloud
    case timeTogether

    var id: Int { rawValue }
}
