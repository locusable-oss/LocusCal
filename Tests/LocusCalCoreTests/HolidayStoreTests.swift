import XCTest
@testable import LocusCalCore

final class HolidayStoreTests: XCTestCase {
    func testMarkRestAndWork() throws {
        let file = HolidayYearFile(year: 2026, days: [
            "2026-01-01": .rest,
            "2026-01-04": .work
        ])
        let store = HolidayStore(files: [file])
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let rest = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
        let work = cal.date(from: DateComponents(year: 2026, month: 1, day: 4, hour: 12))!
        let plain = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 12))!
        XCTAssertEqual(store.mark(on: rest), .rest)
        XCTAssertEqual(store.mark(on: work), .work)
        XCTAssertNil(store.mark(on: plain))
        XCTAssertTrue(store.hasData(for: 2026))
        XCTAssertFalse(store.hasData(for: 2030))
    }

    func test2026LaborDayMakeupMatchesNotice() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root.appendingPathComponent("LocusCal/Resources/holidays-2026.json")
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(HolidayYearFile.self, from: data)
        XCTAssertNil(file.days["2026-04-26"], "May Day notice does not make Apr 26 a workday")
        XCTAssertEqual(file.days["2026-05-09"], .work)
        XCTAssertEqual(file.days["2026-01-04"], .work)
        XCTAssertEqual(file.days["2026-05-01"], .rest)
    }

    func testMonthGridFortyTwoCells() {
        let grid = MonthGrid(year: 2026, month: 9, weekStartsOnMonday: true)
        XCTAssertEqual(grid.days.count, 42)
    }

    func testSeptember2026TuesdayAnchors() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = MonthGrid(year: 2026, month: 9, weekStartsOnMonday: true, calendar: cal)
        let first = monday.days[0]!
        XCTAssertEqual(cal.component(.month, from: first), 8)
        XCTAssertEqual(cal.component(.day, from: first), 31)
        XCTAssertEqual(cal.component(.day, from: monday.days[1]!), 1)

        let sunday = MonthGrid(year: 2026, month: 9, weekStartsOnMonday: false, calendar: cal)
        let sundayFirst = sunday.days[0]!
        XCTAssertEqual(cal.component(.month, from: sundayFirst), 8)
        XCTAssertEqual(cal.component(.day, from: sundayFirst), 30)
    }

    func testStartOfMonthDoesNotKeepDay31() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let jan31 = cal.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let next = startOfMonth(adding: 1, to: jan31, calendar: cal)!
        XCTAssertEqual(cal.component(.month, from: next), 2)
        XCTAssertEqual(cal.component(.day, from: next), 1)
    }

    func testLunarLeapMonthAndDayNames() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        func noon(_ year: Int, _ month: Int, _ day: Int) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        }
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 6, 25)), "六月")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 6, 26)), "初二")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 7, 4)), "初十")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 7, 14)), "二十")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 7, 15)), "廿一")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 7, 24)), "三十")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 7, 25)), "闰六月")
        XCTAssertEqual(LunarHelper.dayLabel(for: noon(2025, 7, 26)), "初二")
    }
}
