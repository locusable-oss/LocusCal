import SwiftUI
import AppKit

struct PopoverRootView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow

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
        openWindow(id: "settings")
        // Bring settings window forward if already open
        DispatchQueue.main.async {
            for window in NSApp.windows where window.identifier?.rawValue == "settings"
                || window.title.contains("设置") {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
