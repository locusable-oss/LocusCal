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
                    Label("设置", systemImage: "gearshape")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("退出", systemImage: "power")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
        // Width only. A fixed height centered this panel and left empty
        // vertical margins when calendar/reminders were not enabled.
        .frame(width: 320, alignment: .top)
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
