import Foundation

public struct MonthGrid: Sendable {
    public let year: Int
    public let month: Int
    /// 42 cells (6 weeks). Leading and trailing cells are neighboring-month dates.
    public let days: [Date?]

    public init(year: Int, month: Int, weekStartsOnMonday: Bool, calendar: Calendar = .current) {
        self.year = year
        self.month = month
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = calendar.timeZone
        cal.locale = calendar.locale
        guard let start = cal.date(from: DateComponents(year: year, month: month, day: 1)) else {
            self.days = Array(repeating: nil, count: 42)
            return
        }
        let weekday = cal.component(.weekday, from: start) // 1 = Sunday … 7 = Saturday
        let offset = weekStartsOnMonday ? (weekday + 5) % 7 : weekday - 1
        var cells: [Date?] = []
        cells.reserveCapacity(42)
        for i in 0..<42 {
            cells.append(cal.date(byAdding: .day, value: i - offset, to: start))
        }
        self.days = cells
    }
}

/// Month step anchored to the 1st, so day 31 cannot land on the last day of a shorter month.
public func startOfMonth(adding delta: Int, to date: Date, calendar: Calendar) -> Date? {
    let parts = calendar.dateComponents([.year, .month], from: date)
    guard let start = calendar.date(from: parts) else { return nil }
    guard delta != 0 else { return start }
    return calendar.date(byAdding: .month, value: delta, to: start)
}
