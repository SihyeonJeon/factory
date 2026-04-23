import Foundation

/// F2: 모든 사용자 표시 시각·날짜를 KST(Asia/Seoul) 기준으로 일관되게 포맷.
enum KSTDateFormatter {
    static let timeZone: TimeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
    static let locale: Locale = Locale(identifier: "ko_KR")

    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = "yyyy년 M월 d일"
        return f
    }()

    static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = "a h:mm"
        return f
    }()

    static let yearMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = "yyyy년 M월"
        return f
    }()

    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = "M월 d일 a h:mm"
        return f
    }()

    /// KST 기준 해당 연-월의 시작 자정 Date (UTC storage 대응).
    static func startOfMonthKST(year: Int, month: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.date(from: components) ?? Date()
    }

    /// 월말 exclusive — 다음 월 시작 자정.
    static func endOfMonthKST(year: Int, month: Int) -> Date {
        let next = month == 12
            ? (year: year + 1, month: 1)
            : (year: year, month: month + 1)
        return startOfMonthKST(year: next.year, month: next.month)
    }

    static func currentYearMonth(_ now: Date = Date()) -> (year: Int, month: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month], from: now)
        return (comps.year ?? 1970, comps.month ?? 1)
    }

    static func isFuture(_ date: Date, now: Date = Date()) -> Bool {
        // KST 기준 오늘 자정 이후를 "미래"로 간주
        let today = truncateToDayKST(now)
        let target = truncateToDayKST(date)
        return target > today
    }

    static func truncateToDayKST(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return cal.date(from: comps) ?? date
    }
}
