import SwiftUI
import AppKit

struct PopoverRootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            MonthCalendarView()
            Divider()
            if appState.preferences.showEventKit {
                EventKitSection()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                Divider()
            }
            HStack {
                Button {
                    openSettings()
                } label: {
                    Label("设置", systemImage: "gear")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("退出") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(10)
        }
        .background(.regularMaterial)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
