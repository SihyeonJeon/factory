import Foundation

// vibe-limit-checked: 5 @MainActor state ownership, 7 deterministic calendar evidence, 12 state transition tests
@MainActor
final class MemoryCalendarStore: ObservableObject {
    @Published private(set) var displayedMonth: Date
    @Published private(set) var selectedDate: Date?
    private(set) var memoryDates: Set<DateComponents>

    private let today: Date
    private var calendar: Calendar

    struct CalendarCell: Hashable {
        let date: Date
        let isCurrentMonth: Bool
        let isToday: Bool
    }

    init(today: Date = Date()) {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        let displayedMonth = calendar.startOfMonth(for: today)
        self.calendar = calendar
        self.today = today
        self.displayedMonth = displayedMonth
        self.selectedDate = nil
        self.memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
    }

    func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
        memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
    }

    func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
        memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
    }

    func select(_ date: Date?) {
        selectedDate = date
    }

    func hasMemory(on components: DateComponents) -> Bool {
        let key = DateComponents(year: components.year, month: components.month, day: components.day)
        return memoryDates.contains(key)
    }

    func memoriesForSelectedDate() -> [SampleMemoryPin] {
        guard let selectedDate else { return [] }
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let matchingIndexes = SampleMemoryPin.samples.indices.filter { index in
            let syntheticComponents = syntheticDateComponents(for: SampleMemoryPin.samples[index], in: displayedMonth)
            return syntheticComponents.year == selectedComponents.year
                && syntheticComponents.month == selectedComponents.month
                && syntheticComponents.day == selectedComponents.day
        }
        return matchingIndexes.map { SampleMemoryPin.samples[$0] }
    }

    func monthTitle() -> String {
        UnfadingLocalized.Calendar.monthYearFormat(displayedMonth)
    }

    func weeks() -> [[CalendarCell]] {
        let startOfMonth = calendar.startOfMonth(for: displayedMonth)
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leadingDays = weekday - calendar.firstWeekday
        let normalizedLeadingDays = leadingDays >= 0 ? leadingDays : leadingDays + 7
        guard let gridStart = calendar.date(byAdding: .day, value: -normalizedLeadingDays, to: startOfMonth) else {
            return []
        }

        return (0..<6).map { weekIndex in
            (0..<7).compactMap { dayIndex in
                guard let date = calendar.date(byAdding: .day, value: weekIndex * 7 + dayIndex, to: gridStart) else {
                    return nil
                }
                return CalendarCell(
                    date: date,
                    isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                    isToday: calendar.isDate(date, inSameDayAs: today)
                )
            }
        }
    }

    private static func seedMemoryDates(for month: Date, calendar: Calendar) -> Set<DateComponents> {
        Set(SampleMemoryPin.samples.map { pin in
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = syntheticDay(for: pin)
            return DateComponents(year: components.year, month: components.month, day: components.day)
        })
    }

    private func syntheticDateComponents(for pin: SampleMemoryPin, in month: Date) -> DateComponents {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = Self.syntheticDay(for: pin)
        return DateComponents(year: components.year, month: components.month, day: components.day)
    }

    private static func syntheticDay(for pin: SampleMemoryPin) -> Int {
        let hash = abs(pin.id.uuidString.reduce(0) { partial, scalar in
            partial &+ Int(scalar.unicodeScalars.first?.value ?? 0)
        })
        return (hash % 28) + 1
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
