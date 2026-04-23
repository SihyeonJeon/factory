import Foundation

struct MemoryAggregator {
    let memories: [DBMemory]
    var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = KSTDateFormatter.timeZone
        return calendar
    }()
    var now: Date = Date()

    var topPlaces: [PlaceBundle] {
        groupedByPlace()
            .sorted { lhs, rhs in
                if lhs.value.count == rhs.value.count {
                    return (lhs.value.map(\.date).max() ?? .distantPast) > (rhs.value.map(\.date).max() ?? .distantPast)
                }
                return lhs.value.count > rhs.value.count
            }
            .prefix(4)
            .enumerated()
            .map { offset, element in
                placeBundle(place: element.key, memories: element.value, tintIndex: offset)
            }
    }

    var recentEvents: [SheetMemoryEvent] {
        memories
            .sorted { $0.date > $1.date }
            .prefix(12)
            .enumerated()
            .map { offset, memory in
                SheetMemoryEvent(
                    id: memory.id,
                    title: memory.title,
                    place: memory.placeTitle,
                    date: memory.date,
                    photoCount: max(memory.homePhotoPaths.count, memory.photoURL == nil ? 0 : 1),
                    photoSymbols: [MemoryMapPinStyle.symbol(for: memory), "camera.fill", "heart.fill"],
                    photoURLs: memory.homePhotoPaths,
                    tintIndex: offset
                )
            }
    }

    var weeklyEvent: SheetMemoryEvent? {
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
        return recentEvents.first { event in
            event.date >= start && event.date < end
        } ?? recentEvents.first
    }

    var monthlyEvents: [SheetMemoryEvent] {
        let currentMonth = recentEvents.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        return Array((currentMonth.isEmpty ? recentEvents : currentMonth).prefix(8))
    }

    var archiveEvents: [SheetMemoryEvent] {
        recentEvents
    }

    var placeBundles: [PlaceBundle] {
        topPlaces
    }

    var totalArchivePhotoCount: Int {
        archiveEvents.reduce(0) { $0 + $1.photoCount }
    }

    private func groupedByPlace() -> [String: [DBMemory]] {
        Dictionary(grouping: memories) { memory in
            let trimmed = memory.placeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "장소 없음" : trimmed
        }
    }

    private func placeBundle(place: String, memories: [DBMemory], tintIndex: Int) -> PlaceBundle {
        let sorted = memories.sorted { $0.date > $1.date }
        let photoPaths = sorted.flatMap(\.homePhotoPaths)
        return PlaceBundle(
            id: sorted.first?.id ?? UUID(),
            place: place,
            visitCount: memories.count,
            photoCount: max(photoPaths.count, memories.reduce(0) { $0 + ($1.photoURL == nil ? 0 : 1) }),
            photoSymbols: Array(sorted.map { MemoryMapPinStyle.symbol(for: $0) }.prefix(3)),
            photoURLs: Array(photoPaths.prefix(3)),
            tintIndex: tintIndex
        )
    }
}
