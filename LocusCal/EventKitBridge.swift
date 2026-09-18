import Foundation
import Combine
import EventKit
import AppKit

/// Drops NotificationCenter tokens with the bridge.
private final class EventKitObserverBag {
    private var tokens: [NSObjectProtocol] = []

    func add(_ token: NSObjectProtocol) {
        tokens.append(token)
    }

    deinit {
        let center = NotificationCenter.default
        for token in tokens {
            center.removeObserver(token)
        }
    }
}

private func displayTitle(_ raw: String?, fallback: String) -> String {
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? fallback : trimmed
}

private func dueSortKey(_ reminder: EKReminder) -> Date {
    guard let parts = reminder.dueDateComponents else { return .distantFuture }
    return Calendar.current.date(from: parts) ?? .distantFuture
}

@MainActor
final class EventKitBridge: ObservableObject {
    @Published var events: [String] = []
    @Published var reminders: [String] = []
    @Published private(set) var isRefreshing = false

    private struct Access: Equatable {
        var events: Bool
        var reminders: Bool

        var any: Bool { events || reminders }
    }

    private var store = EKEventStore()
    private let observers = EventKitObserverBag()
    private weak var preferences: AppPreferences?
    /// Access the current store was opened with. A store created before a grant
    /// does not see calendar/reminder sources until it is reset or replaced.
    private var accessSnapshot: Access?
    private var reminderFetchGeneration = 0
    private var accessFlowInFlight = false
    private var changeTask: Task<Void, Never>?

    init() {
        let center = NotificationCenter.default
        observers.add(center.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reloadFromSystemChange()
            }
        })
        // Grants made in System Settings show up when the app is foregrounded again.
        observers.add(center.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reloadFromSystemChange()
            }
        })
    }

    func bind(_ preferences: AppPreferences) {
        self.preferences = preferences
        if preferences.showEventKit {
            applyExternalChange()
        }
    }

    func requestAccessIfNeeded() async {
        if accessFlowInFlight { return }
        accessFlowInFlight = true
        isRefreshing = true
        defer { accessFlowInFlight = false }
        changeTask?.cancel()

        if Self.shouldRequestFullAccess(.event) {
            do { _ = try await store.requestFullAccessToEvents() } catch {}
        }
        // Yield so a second system prompt is not dropped on the same turn.
        await Task.yield()
        if Self.shouldRequestFullAccess(.reminder) {
            do { _ = try await store.requestFullAccessToReminders() } catch {}
        }
        let access = Self.currentAccess()
        let changed = access != accessSnapshot
        accessSnapshot = access
        if access.any {
            ensureReadableStore(accessChanged: changed)
        }
        reloadToday(access)
    }

    /// Live refresh for EKEventStoreChanged and app activation. Never prompts.
    func reloadFromSystemChange() {
        guard preferences?.showEventKit == true else { return }
        changeTask?.cancel()
        changeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            self.applyExternalChange()
        }
    }

    private func applyExternalChange() {
        guard preferences?.showEventKit == true else { return }
        let access = Self.currentAccess()
        let changed = access != accessSnapshot
        accessSnapshot = access
        guard access.any else {
            publishEvents([])
            publishReminders([])
            isRefreshing = false
            return
        }
        ensureReadableStore(accessChanged: changed)
        reloadToday(access)
    }

    /// Refresh first. Rebuild only after a grant or when sources are still missing,
    /// so a normal reopen does not reset a store that already sees calendars.
    private func ensureReadableStore(accessChanged: Bool) {
        if accessChanged {
            prepareStoreForReading()
            return
        }
        store.refreshSourcesIfNecessary()
        if store.sources.isEmpty {
            prepareStoreForReading()
        }
    }

    /// Apple: if the store was used before access, call reset() or calendars stay empty.
    /// On macOS a fresh store is the fallback when sources are still missing after reset.
    private func prepareStoreForReading() {
        store.reset()
        store.refreshSourcesIfNecessary()
        guard store.sources.isEmpty else { return }
        let fresh = EKEventStore()
        fresh.refreshSourcesIfNecessary()
        store = fresh
        if store.sources.isEmpty {
            store.reset()
            store.refreshSourcesIfNecessary()
        }
    }

    private static func currentAccess() -> Access {
        Access(events: canRead(.event), reminders: canRead(.reminder))
    }

    private static func canRead(_ type: EKEntityType) -> Bool {
        switch EKEventStore.authorizationStatus(for: type) {
        case .fullAccess, .authorized:
            return true
        default:
            return false
        }
    }

    private static func shouldRequestFullAccess(_ type: EKEntityType) -> Bool {
        switch EKEventStore.authorizationStatus(for: type) {
        case .notDetermined, .writeOnly:
            return true
        default:
            return false
        }
    }

    private func reloadToday(_ access: Access) {
        reminderFetchGeneration &+= 1
        let generation = reminderFetchGeneration
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            isRefreshing = false
            return
        }

        if access.events {
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
            let lines = store.events(matching: predicate)
                .sorted { $0.startDate < $1.startDate }
                .prefix(8)
                .map { eventLine($0, dayStart: start, calendar: calendar) }
            publishEvents(Array(lines))
        } else {
            publishEvents([])
        }

        guard access.reminders else {
            publishReminders([])
            isRefreshing = false
            return
        }

        isRefreshing = true
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: nil
        )
        store.fetchReminders(matching: predicate) { [weak self] items in
            let titles = (items ?? [])
                .sorted { dueSortKey($0) < dueSortKey($1) }
                .prefix(8)
                .map { displayTitle($0.title, fallback: "提醒") }
            Task { @MainActor in
                guard let self, self.reminderFetchGeneration == generation else { return }
                self.publishReminders(titles)
                self.isRefreshing = false
            }
        }
    }

    private func eventLine(_ event: EKEvent, dayStart: Date, calendar: Calendar) -> String {
        let title = displayTitle(event.title, fallback: "无标题")
        if event.isAllDay {
            return "全天 \(title)"
        }
        if !calendar.isDate(event.startDate, inSameDayAs: dayStart) {
            return "跨天 \(title)"
        }
        let time = DateFormatter.localizedString(
            from: event.startDate,
            dateStyle: .none,
            timeStyle: .short
        )
        return "\(time) \(title)"
    }

    private func publishEvents(_ next: [String]) {
        if events != next { events = next }
    }

    private func publishReminders(_ next: [String]) {
        if reminders != next { reminders = next }
    }
}
