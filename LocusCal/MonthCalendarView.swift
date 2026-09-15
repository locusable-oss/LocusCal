import SwiftUI

struct MonthCalendarView: View {
    @EnvironmentObject private var appState: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            header
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(appState.grid.days.enumerated()), id: \.offset) { _, date in
                    dayCell(date)
                }
            }
            if !appState.holidays.hasData(for: appState.year) {
                Text("本年度节假日数据未嵌入，格子无放假/补班标注")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
    }

    private var header: some View {
        HStack {
            Button { appState.shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            Spacer()
            Text(headerTitle)
                .font(.headline)
            Spacer()
            Button("今天") { appState.goToday() }
                .buttonStyle(.borderless)
            Button { appState.shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
    }

    private var headerTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月"
        return f.string(from: appState.visibleMonth)
    }

    private var weekdayHeader: some View {
        let labels = appState.preferences.weekStartsOnMonday
            ? ["一", "二", "三", "四", "五", "六", "日"]
            : ["日", "一", "二", "三", "四", "五", "六"]
        return HStack(spacing: 2) {
            ForEach(labels, id: \.self) { t in
                Text(t)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        let inMonth = appState.isInVisibleMonth(date)
        let today = appState.isSameDay(date, Date())
        let mark = date.flatMap { appState.holidays.mark(on: $0) }
        VStack(spacing: 1) {
            Text(dayNumber(date))
                .font(.system(size: 13, weight: today ? .semibold : .regular))
                .foregroundStyle(inMonth ? Color.primary : Color.secondary.opacity(0.45))
            if appState.preferences.showLunar, let date, inMonth,
               let lunar = LunarHelper.dayLabel(for: date) {
                Text(lunar)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text(" ")
                    .font(.system(size: 8))
            }
            markBadge(mark)
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(today ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(today ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
    }

    private func dayNumber(_ date: Date?) -> String {
        guard let date else { return "" }
        return String(Calendar.current.component(.day, from: date))
    }

    @ViewBuilder
    private func markBadge(_ mark: DayMark?) -> some View {
        switch mark {
        case .rest:
            Text("休")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.red)
        case .work:
            Text("班")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.blue)
        case nil:
            Text(" ")
                .font(.system(size: 8))
        }
    }
}
