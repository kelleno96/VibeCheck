import Foundation

enum DateHelpers {
    static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Returns the start date (first day) of the given year.
    static func startOfYear(for year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Returns all dates in the given year up to and including today (or Dec 31 if the year is in the past).
    static func datesInYear(_ year: Int) -> [Date] {
        let calendar = Calendar.current
        let start = startOfYear(for: year)

        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = 12
        endComponents.day = 31
        let endOfYear = calendar.date(from: endComponents) ?? Date()

        let end = min(endOfYear, startOfDay(for: Date()))

        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    /// Returns the weekday index (0 = Sunday, 6 = Saturday) for a given date.
    static func weekdayIndex(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday - 1 // Calendar weekday is 1-based (1 = Sunday)
    }

    /// Returns the current year as an Int.
    nonisolated static var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}
