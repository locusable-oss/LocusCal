import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let preferences = AppPreferences()
    let holidays: HolidayStore
    @Published var visibleMonth: Date
    @Published var eventKit = EventKitBridge()
    @Published var refreshTick = 0

    private let calendar = Calendar.current
    private var eventKitForward: AnyCancellable?

    init(holidays: HolidayStore = .loadFromBundle()) {
        self.holidays = holidays
        self.visibleMonth = Date()
        eventKit.bind(preferences)
        // Nested ObservableObject updates do not refresh MenuBarExtra on their own.
        eventKitForward = eventKit.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func bump() { refreshTick &+= 1 }

    var menuBarTitle: String {
        var parts: [String] = []
        if preferences.menuBarShowsDate {
            let f = DateFormatter()
            f.locale = Locale(identifier: "zh_CN")
            f.dateFormat = "M/d"
            parts.append(f.string(from: Date()))
        }
        if preferences.menuBarShowsHoliday, let s = holidays.summary(on: Date()) {
            parts.append(s)
        }
        if parts.isEmpty { return "历" }
        return parts.joined(separator: " ")
    }

    func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = d
        }
    }

    func goToday() {
        visibleMonth = Date()
    }

    var year: Int { calendar.component(.year, from: visibleMonth) }
    var month: Int { calendar.component(.month, from: visibleMonth) }

    var grid: MonthGrid {
        MonthGrid(year: year, month: month, weekStartsOnMonday: preferences.weekStartsOnMonday, calendar: calendar)
    }

    func isSameDay(_ a: Date?, _ b: Date) -> Bool {
        guard let a else { return false }
        return calendar.isDate(a, inSameDayAs: b)
    }

    func isInVisibleMonth(_ date: Date?) -> Bool {
        guard let date else { return false }
        return calendar.component(.month, from: date) == month
            && calendar.component(.year, from: date) == year
    }
}
