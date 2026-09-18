import SwiftUI
import AppKit

@main
struct LocusCalApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environmentObject(appState)
        } label: {
            Text(appState.menuBarTitle)
        }
        .menuBarExtraStyle(.window)

        // Dedicated window: MenuBarExtra + LSUIElement often cannot open Settings scene via showSettingsWindow:
        Window("LocusCal 设置", id: "settings") {
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 400, minHeight: 380)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 440, height: 460)

        // Keep Settings for system Cmd+, when available
        Settings {
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 400, minHeight: 380)
        }
    }
}
