import Foundation
import Combine
import ServiceManagement

@MainActor
final class AppPreferences: ObservableObject {
    @Published var showLunar: Bool {
        didSet { UserDefaults.standard.set(showLunar, forKey: Keys.showLunar) }
    }
    @Published var weekStartsOnMonday: Bool {
        didSet { UserDefaults.standard.set(weekStartsOnMonday, forKey: Keys.weekStartsOnMonday) }
    }
    @Published var menuBarShowsHoliday: Bool {
        didSet { UserDefaults.standard.set(menuBarShowsHoliday, forKey: Keys.menuBarShowsHoliday) }
    }
    @Published var menuBarShowsDate: Bool {
        didSet { UserDefaults.standard.set(menuBarShowsDate, forKey: Keys.menuBarShowsDate) }
    }
    @Published var showEventKit: Bool {
        didSet { UserDefaults.standard.set(showEventKit, forKey: Keys.showEventKit) }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            guard !suppressLaunchAtLoginWrite else { return }
            applyLaunchAtLogin()
        }
    }

    /// System Settings is the source of truth. A failed register must not leave the toggle on.
    private var suppressLaunchAtLoginWrite = false

    private enum Keys {
        static let showLunar = "showLunar"
        static let weekStartsOnMonday = "weekStartsOnMonday"
        static let menuBarShowsHoliday = "menuBarShowsHoliday"
        static let menuBarShowsDate = "menuBarShowsDate"
        static let showEventKit = "showEventKit"
        static let launchAtLogin = "launchAtLogin"
    }

    init() {
        let defaults = UserDefaults.standard
        showLunar = defaults.object(forKey: Keys.showLunar) as? Bool ?? true
        weekStartsOnMonday = defaults.object(forKey: Keys.weekStartsOnMonday) as? Bool ?? true
        menuBarShowsHoliday = defaults.object(forKey: Keys.menuBarShowsHoliday) as? Bool ?? true
        menuBarShowsDate = defaults.object(forKey: Keys.menuBarShowsDate) as? Bool ?? true
        showEventKit = defaults.object(forKey: Keys.showEventKit) as? Bool ?? false
        launchAtLogin = Self.systemLaunchAtLogin
    }

    private static var systemLaunchAtLogin: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        default:
            return false
        }
    }

    private func applyLaunchAtLogin() {
        UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
        do {
            let status = SMAppService.mainApp.status
            if launchAtLogin {
                if status != .enabled && status != .requiresApproval {
                    try SMAppService.mainApp.register()
                }
            } else if status == .enabled || status == .requiresApproval {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let actual = Self.systemLaunchAtLogin
            UserDefaults.standard.set(actual, forKey: Keys.launchAtLogin)
            suppressLaunchAtLoginWrite = true
            launchAtLogin = actual
            suppressLaunchAtLoginWrite = false
        }
    }
}
