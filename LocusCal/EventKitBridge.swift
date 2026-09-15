import Foundation
import Combine
import EventKit

@MainActor
final class EventKitBridge: ObservableObject {
    @Published var events: [String] = []
    @Published var reminders: [String] = []
    @Published var statusText: String = "未请求权限"

    private let store = EKEventStore()

    func requestAccessIfNeeded() async {
        do {
            if #available(macOS 14.0, *) {
                let cal = try await store.requestFullAccessToEvents()
                let rem = try await store.requestFullAccessToReminders()
                statusText = (cal || rem) ? "已授权（只读展示）" : "权限被拒绝"
            } else {
                let cal = try await store.requestAccess(to: .event)
                let rem = try await store.requestAccess(to: .reminder)
                statusText = (cal || rem) ? "已授权（只读展示）" : "权限被拒绝"
            }
            reloadToday()
        } catch {
            statusText = "权限请求失败"
            events = []
            reminders = []
        }
    }

    func reloadToday() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let todayEvents = store.events(matching: predicate)
        events = todayEvents.prefix(8).map { e in
            let t = DateFormatter.localizedString(from: e.startDate, dateStyle: .none, timeStyle: .short)
            return "\(t) \(e.title ?? "无标题")"
        }

        let remPred = store.predicateForIncompleteReminders(withDueDateStarting: start, ending: end, calendars: nil)
        store.fetchReminders(matching: remPred) { [weak self] items in
            let titles = (items ?? []).prefix(8).map { $0.title ?? "提醒" }
            Task { @MainActor in
                self?.reminders = Array(titles)
            }
        }
    }
}
