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

        Settings {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 360, height: 280)
        }
    }
}
