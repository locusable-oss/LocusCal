import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    let preferences = AppPreferences()
    let holidays: HolidayStore
    @Published var visibleMonth: Date
    @Published var eventKit = EventKitBridge()
    @Published var refreshTick = 0

    private var cancellables: Set<AnyCancellable> = []
    private var dayTimer: Timer?

    /// Always Gregorian. Calendar.current can be Japanese/Buddhist and would shift the public-holiday year.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }

    init(holidays: HolidayStore = .loadFromBundle()) {
        self.holidays = holidays
        self.visibleMonth = Date()
        preferences.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        eventKit.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        eventKit.bind(preferences)
        armDayRefresh()
    }

    deinit {
        dayTimer?.invalidate()
    }

    func bump() { refreshTick &+= 1 }

    var menuBarTitle: String {
        var parts: [String] = []
        if preferences.menuBarShowsDate {
            parts.append(formatted(Date(), "M/d"))
        }
        if preferences.menuBarShowsHoliday, let summary = holidays.summary(on: Date()) {
            parts.append(summary)
        }
        if parts.isEmpty { return "历" }
        return parts.joined(separator: " ")
    }

    var monthHeading: String {
        formatted(visibleMonth, "yyyy年M月")
    }

    func dayNumber(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    func shiftMonth(_ delta: Int) {
        if let next = startOfMonth(adding: delta, to: visibleMonth, calendar: calendar) {
            visibleMonth = next
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

    func isSameDay(_ date: Date?, _ other: Date) -> Bool {
        guard let date else { return false }
        return calendar.isDate(date, inSameDayAs: other)
    }

    func isInVisibleMonth(_ date: Date?) -> Bool {
        guard let date else { return false }
        return calendar.component(.month, from: date) == month
            && calendar.component(.year, from: date) == year
    }

    private func formatted(_ date: Date, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    private func armDayRefresh() {
        dayTimer?.invalidate()
        let start = calendar.startOfDay(for: Date())
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else { return }
        let interval = max(1, next.timeIntervalSinceNow + 0.5)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.bump()
                self?.armDayRefresh()
            }
        }
        timer.tolerance = 30
        RunLoop.main.add(timer, forMode: .common)
        dayTimer = timer
    }
}
