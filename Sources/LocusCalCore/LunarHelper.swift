import Foundation

/// Lunar label for the civil date in the current time zone.
/// The first day of a month is 正月 / 闰六月; other days are 初一…三十.
/// Evaluated at noon in China so the label does not flip around local midnight.
public enum LunarHelper {
    public static func dayLabel(for date: Date) -> String? {
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = .current
        let ymd = civil.dateComponents([.year, .month, .day], from: date)
        guard let year = ymd.year, let month = ymd.month, let day = ymd.day else { return nil }

        var china = Calendar(identifier: .gregorian)
        china.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? civil.timeZone
        guard let noon = china.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
            return nil
        }

        var lunar = Calendar(identifier: .chinese)
        lunar.timeZone = china.timeZone
        lunar.locale = Locale(identifier: "zh_CN")
        let parts = lunar.dateComponents([.month, .day, .isLeapMonth], from: noon)
        guard let lunarDay = parts.day, (1...30).contains(lunarDay) else { return nil }
        if lunarDay == 1 {
            guard let lunarMonth = parts.month else { return nil }
            let prefix = parts.isLeapMonth == true ? "闰" : ""
            return prefix + monthName(lunarMonth) + "月"
        }
        return dayName(lunarDay)
    }

    private static func monthName(_ month: Int) -> String {
        let names = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        guard names.indices.contains(month - 1) else { return String(month) }
        return names[month - 1]
    }

    private static func dayName(_ day: Int) -> String {
        let ones = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch day {
        case 10: return "初十"
        case 20: return "二十"
        case 30: return "三十"
        case 1...9: return "初" + ones[day - 1]
        case 11...19: return "十" + ones[(day % 10) - 1]
        case 21...29: return "廿" + ones[(day % 10) - 1]
        default: return String(day)
        }
    }
}
