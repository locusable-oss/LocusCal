import SwiftUI
import AppKit

@main
struct LocusCalApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environmentObject(appState)
                .frame(width: 320, height: 420)
        } label: {
            Text(appState.menuBarTitle)
        }
        .menuBarExtraStyle(.window)

        // Dedicated window: MenuBarExtra + LSUIElement often cannot open Settings scene via showSettingsWindow:
        Window("LocusCal 设置", id: "settings") {
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 360, minHeight: 300)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 320)

        // Keep Settings for system Cmd+, when available
        Settings {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 360, height: 280)
        }
    }
}
