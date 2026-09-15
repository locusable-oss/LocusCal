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
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let rest = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let work = cal.date(from: DateComponents(year: 2026, month: 1, day: 4))!
        let plain = cal.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        XCTAssertEqual(store.mark(on: rest), .rest)
        XCTAssertEqual(store.mark(on: work), .work)
        XCTAssertNil(store.mark(on: plain))
        XCTAssertTrue(store.hasData(for: 2026))
        XCTAssertFalse(store.hasData(for: 2030))
    }

    func testMonthGridFortyTwoCells() {
        let g = MonthGrid(year: 2026, month: 9, weekStartsOnMonday: true)
        XCTAssertEqual(g.days.count, 42)
    }
}
