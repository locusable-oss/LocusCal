import Foundation

public enum DayMark: String, Codable, Sendable {
    case rest
    case work
}

public struct HolidayYearFile: Codable, Sendable {
    public var year: Int
    public var source: String?
    public var days: [String: DayMark]

    public init(year: Int, source: String? = nil, days: [String: DayMark] = [:]) {
        self.year = year
        self.source = source
        self.days = days
    }
}

public struct HolidayStore: Sendable {
    private let byYear: [Int: HolidayYearFile]

    public init(files: [HolidayYearFile]) {
        var map: [Int: HolidayYearFile] = [:]
        for file in files { map[file.year] = file }
        self.byYear = map
    }

    public static func loadFromBundle(_ bundle: Bundle = .main) -> HolidayStore {
        var files: [HolidayYearFile] = []
        for year in 2024...2035 {
            guard let url = bundle.url(forResource: "holidays-\(year)", withExtension: "json") else { continue }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(HolidayYearFile.self, from: data)
                files.append(decoded)
            } catch {
                // degrade: skip unreadable year
                continue
            }
        }
        return HolidayStore(files: files)
    }

    /// Gregorian civil date in the current time zone. A non-Gregorian system calendar must not change the year key.
    public func mark(on date: Date) -> DayMark? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        let key = String(format: "%04d-%02d-%02d", year, month, day)
        return byYear[year]?.days[key]
    }

    public func hasData(for year: Int) -> Bool {
        guard let file = byYear[year] else { return false }
        return !file.days.isEmpty
    }

    public func summary(on date: Date) -> String? {
        switch mark(on: date) {
        case .rest: return "休"
        case .work: return "班"
        case nil: return nil
        }
    }
}
