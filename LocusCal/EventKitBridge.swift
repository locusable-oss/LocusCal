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

@MainActor
final class EventKitBridge: ObservableObject {
    @Published var events: [String] = []
    @Published var reminders: [String] = []

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
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        if access.events {
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
            let lines = store.events(matching: predicate)
                .sorted { $0.startDate < $1.startDate }
                .prefix(8)
                .map { event -> String in
                    let time = DateFormatter.localizedString(
                        from: event.startDate,
                        dateStyle: .none,
                        timeStyle: .short
                    )
                    return "\(time) \(event.title ?? "无标题")"
                }
            publishEvents(Array(lines))
        } else {
            publishEvents([])
        }

        guard access.reminders else {
            publishReminders([])
            return
        }
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: nil
        )
        store.fetchReminders(matching: predicate) { [weak self] items in
            let titles = Array((items ?? []).prefix(8).map { $0.title ?? "提醒" })
            Task { @MainActor in
                guard let self, self.reminderFetchGeneration == generation else { return }
                self.publishReminders(titles)
            }
        }
    }

    private func publishEvents(_ next: [String]) {
        if events != next { events = next }
    }

    private func publishReminders(_ next: [String]) {
        if reminders != next { reminders = next }
    }
}
