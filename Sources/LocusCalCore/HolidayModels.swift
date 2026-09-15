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
    private let dateFormatter: DateFormatter

    public init(files: [HolidayYearFile]) {
        var map: [Int: HolidayYearFile] = [:]
        for f in files { map[f.year] = f }
        self.byYear = map
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = df
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

    public func mark(on date: Date) -> DayMark? {
        let key = dateFormatter.string(from: date)
        let year = Calendar.current.component(.year, from: date)
        return byYear[year]?.days[key]
    }

    public func hasData(for year: Int) -> Bool {
        guard let f = byYear[year] else { return false }
        return !f.days.isEmpty
    }

    public func summary(on date: Date) -> String? {
        switch mark(on: date) {
        case .rest: return "休"
        case .work: return "班"
        case nil: return nil
        }
    }
}
