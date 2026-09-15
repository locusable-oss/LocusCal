import Foundation

/// Lightweight lunar day label for display (approximation suitable for menu-bar annotation).
/// Uses ChineseCalendar when available; returns nil on failure.
public enum LunarHelper {
    public static func dayLabel(for date: Date, calendar: Calendar = .current) -> String? {
        var lunar = Calendar(identifier: .chinese)
        lunar.locale = Locale(identifier: "zh_CN")
        let day = lunar.component(.day, from: date)
        if day == 1 {
            let month = lunar.component(.month, from: date)
            return lunarMonthName(month) + "月"
        }
        return lunarDayName(day)
    }

    private static func lunarMonthName(_ m: Int) -> String {
        let names = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        let idx = max(0, min(names.count - 1, m - 1))
        return names[idx]
    }

    private static func lunarDayName(_ d: Int) -> String {
        let digits = ["初", "十", "廿", "卅"]
        let ones = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        if d == 10 { return "初十" }
        if d == 20 { return "二十" }
        if d == 30 { return "三十" }
        let tens = d / 10
        let one = d % 10
        if tens == 0 { return digits[0] + ones[one - 1] }
        if one == 0 { return digits[tens] }
        return digits[tens] + ones[one - 1]
    }
}
