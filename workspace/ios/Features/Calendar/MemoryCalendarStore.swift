import Foundation

// vibe-limit-checked: 5 @MainActor state ownership, 7 deterministic calendar evidence, 12 state transition tests
@MainActor
final class MemoryCalendarStore: ObservableObject {
    @Published private(set) var displayedMonth: Date
    @Published private(set) var selectedDate: Date?
    @Published private(set) var plannedEvents: [DBEvent] = []
    @Published private(set) var monthlyExpense: Int64 = 0
    private(set) var memoryDates: Set<DateComponents>

    private let today: Date
    private var calendar: Calendar
    private let eventRepo: EventRepository?

    struct CalendarCell: Hashable {
        let date: Date
        let isCurrentMonth: Bool
        let isToday: Bool
    }

    init(today: Date = Date(), eventRepo: EventRepository? = SupabaseEventRepository()) {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = KSTDateFormatter.timeZone
        let displayedMonth = calendar.startOfMonth(for: today)
        self.calendar = calendar
        self.today = today
        self.displayedMonth = displayedMonth
        self.selectedDate = nil
        self.memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
        self.eventRepo = eventRepo
        applyUITestStubIfNeeded()
    }

    func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
        memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
        applyUITestStubIfNeeded()
    }

    func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
        memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
        applyUITestStubIfNeeded()
    }

    func setDisplayedMonth(year: Int, month: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        displayedMonth = calendar.date(from: components) ?? displayedMonth
        selectedDate = nil
        memoryDates = Self.seedMemoryDates(for: displayedMonth, calendar: calendar)
        applyUITestStubIfNeeded()
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

    // MARK: F9/F2-cal — Supabase 기반 월 지출 + 계획 이벤트 로드 (KST)
    func loadMonth(for groupId: UUID) async {
        if ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1" {
            applyUITestStubIfNeeded()
            return
        }
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        let year = comps.year ?? 1970
        let month = comps.month ?? 1
        let startUTC = KSTDateFormatter.startOfMonthKST(year: year, month: month)
        let endUTC = KSTDateFormatter.endOfMonthKST(year: year, month: month)
        guard let repo = eventRepo else { return }
        async let events = (try? await repo.plannedEvents(groupId: groupId, startUTC: startUTC, endUTC: endUTC)) ?? []
        async let expense = (try? await repo.monthlyExpenseKST(groupId: groupId, year: year, month: month)) ?? 0
        let (e, x) = await (events, expense)
        self.plannedEvents = e
        self.monthlyExpense = x
    }

    /// 주어진 날짜가 KST 기준 미래인지 (오늘 자정 이후).
    func isFutureDate(_ date: Date) -> Bool {
        KSTDateFormatter.isFuture(date)
    }

    /// 주어진 날짜에 계획(이벤트) 존재 여부 — start ≤ date ≤ end 포함.
    func hasPlan(on date: Date) -> Bool {
        let day = KSTDateFormatter.truncateToDayKST(date)
        return plannedEvents.contains { event in
            let start = KSTDateFormatter.truncateToDayKST(event.startDate)
            let end = KSTDateFormatter.truncateToDayKST(event.endDate ?? event.startDate)
            return day >= start && day <= end
        }
    }

    enum DayKind: Equatable { case none, memory, plan, both }

    func dayKind(_ date: Date) -> DayKind {
        let m = hasMemory(on: calendar.dateComponents([.year, .month, .day], from: date))
        let p = hasPlan(on: date)
        switch (m, p) {
        case (true, true):   return .both
        case (true, false):  return .memory
        case (false, true):  return .plan
        default:             return .none
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

    private func applyUITestStubIfNeeded() {
        guard ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1" else { return }
        let todayStart = KSTDateFormatter.truncateToDayKST(today)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart) else { return }
        guard calendar.isDate(tomorrow, equalTo: displayedMonth, toGranularity: .month) else {
            plannedEvents = []
            return
        }
        let groupId = UUID(uuidString: "11111111-1111-4111-8111-111111111117") ?? UUID()
        plannedEvents = [
            DBEvent(
                id: UUID(uuidString: "44444444-4444-4444-8444-444444444447") ?? UUID(),
                groupId: groupId,
                title: "성수에서 만나요",
                startDate: tomorrow.addingTimeInterval(60 * 60 * 19),
                endDate: nil,
                isMultiDay: false,
                createdAt: today,
                reminderAt: nil
            )
        ]
        selectedDate = tomorrow
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
