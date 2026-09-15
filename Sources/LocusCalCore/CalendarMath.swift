import Foundation

public struct MonthGrid: Sendable {
    public let year: Int
    public let month: Int
    /// 42 cells (6 weeks), nil = outside month padding still carries a Date for marking neighbors.
    public let days: [Date?]

    public init(year: Int, month: Int, weekStartsOnMonday: Bool, calendar: Calendar = .current) {
        self.year = year
        self.month = month
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        guard let start = cal.date(from: DateComponents(year: year, month: month, day: 1)) else {
            self.days = Array(repeating: nil, count: 42)
            return
        }
        let weekday = cal.component(.weekday, from: start) // 1=Sun ... 7=Sat
        let offset: Int
        if weekStartsOnMonday {
            offset = (weekday + 5) % 7 // Mon=0
        } else {
            offset = weekday - 1
        }
        var cells: [Date?] = []
        for i in 0..<42 {
            let dayOffset = i - offset
            cells.append(cal.date(byAdding: .day, value: dayOffset, to: start))
        }
        self.days = cells
    }
}
