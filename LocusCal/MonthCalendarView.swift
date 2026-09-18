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
        HStack(spacing: 4) {
            HStack(spacing: 0) {
                monthStepButton(delta: -1, systemImage: "chevron.left", label: "上个月")
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            Text(appState.monthHeading)
                .font(.headline)
                .lineLimit(1)
                .layoutPriority(1)

            HStack(spacing: 2) {
                Spacer(minLength: 0)
                Button("今天") { appState.goToday() }
                    .buttonStyle(.borderless)
                    .disabled(appState.isInVisibleMonth(Date()))
                monthStepButton(delta: 1, systemImage: "chevron.right", label: "下个月")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func monthStepButton(delta: Int, systemImage: String, label: String) -> some View {
        Button { appState.shiftMonth(delta) } label: {
            Image(systemName: systemImage)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }

    private var weekdayHeader: some View {
        let labels = appState.preferences.weekStartsOnMonday
            ? ["一", "二", "三", "四", "五", "六", "日"]
            : ["日", "一", "二", "三", "四", "五", "六"]
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(weekdayName(label))
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        let inMonth = appState.isInVisibleMonth(date)
        let today = appState.isSameDay(date, Date())
        let mark = date.flatMap { appState.holidays.mark(on: $0) }
        let showLunar = appState.preferences.showLunar
        VStack(spacing: 1) {
            Text(dayNumber(date))
                .font(.system(size: 13, weight: today ? .semibold : .regular))
                .foregroundStyle(dayColor(today: today, inMonth: inMonth))
            if showLunar {
                Text(lunarText(date))
                    .font(.system(size: 8))
                    .foregroundStyle(inMonth ? Color.secondary : Color.secondary.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            markBadge(mark, inMonth: inMonth)
        }
        .frame(maxWidth: .infinity, minHeight: showLunar ? 36 : 28)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(today ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(today ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cellLabel(date, mark: mark, today: today))
    }

    private func dayNumber(_ date: Date?) -> String {
        guard let date else { return "" }
        return String(appState.dayNumber(date))
    }

    private func lunarText(_ date: Date?) -> String {
        guard let date, let label = LunarHelper.dayLabel(for: date) else { return " " }
        return label
    }

    private func dayColor(today: Bool, inMonth: Bool) -> Color {
        if today { return .accentColor }
        if inMonth { return .primary }
        return Color.secondary.opacity(0.45)
    }

    private func markBadge(_ mark: DayMark?, inMonth: Bool) -> some View {
        let text: String
        let color: Color
        switch mark {
        case .rest:
            text = "休"
            color = .red
        case .work:
            text = "班"
            color = .blue
        case nil:
            text = " "
            color = .clear
        }
        return Text(text)
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(color)
            .opacity(inMonth || mark == nil ? 1 : 0.4)
    }

    private func cellLabel(_ date: Date?, mark: DayMark?, today: Bool) -> String {
        guard let date else { return "空白" }
        var parts = ["\(appState.dayNumber(date))日"]
        if appState.preferences.showLunar, let lunar = LunarHelper.dayLabel(for: date), lunar != " " {
            parts.append(lunar)
        }
        switch mark {
        case .rest: parts.append("放假")
        case .work: parts.append("补班")
        case nil: break
        }
        if today { parts.append("今天") }
        if !appState.isInVisibleMonth(date) { parts.append("邻月") }
        return parts.joined(separator: " ")
    }

    private func weekdayName(_ short: String) -> String {
        switch short {
        case "一": return "周一"
        case "二": return "周二"
        case "三": return "周三"
        case "四": return "周四"
        case "五": return "周五"
        case "六": return "周六"
        case "日": return "周日"
        default: return short
        }
    }
}
