import Foundation
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
        didSet { applyLaunchAtLogin() }
    }

    private enum Keys {
        static let showLunar = "showLunar"
        static let weekStartsOnMonday = "weekStartsOnMonday"
        static let menuBarShowsHoliday = "menuBarShowsHoliday"
        static let menuBarShowsDate = "menuBarShowsDate"
        static let showEventKit = "showEventKit"
        static let launchAtLogin = "launchAtLogin"
    }

    init() {
        let d = UserDefaults.standard
        showLunar = d.object(forKey: Keys.showLunar) as? Bool ?? true
        weekStartsOnMonday = d.object(forKey: Keys.weekStartsOnMonday) as? Bool ?? true
        menuBarShowsHoliday = d.object(forKey: Keys.menuBarShowsHoliday) as? Bool ?? true
        menuBarShowsDate = d.object(forKey: Keys.menuBarShowsDate) as? Bool ?? true
        showEventKit = d.object(forKey: Keys.showEventKit) as? Bool ?? false
        launchAtLogin = d.object(forKey: Keys.launchAtLogin) as? Bool ?? false
    }

    private func applyLaunchAtLogin() {
        UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // degrade silently; Settings can re-toggle
            }
        }
    }
}
