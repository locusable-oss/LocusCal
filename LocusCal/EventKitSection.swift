import SwiftUI

struct EventKitSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今天")
                .font(.subheadline.weight(.semibold))
            if appState.eventKit.events.isEmpty && appState.eventKit.reminders.isEmpty {
                Text("暂无事项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(appState.eventKit.events.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.caption).lineLimit(1)
                }
                ForEach(Array(appState.eventKit.reminders.enumerated()), id: \.offset) { _, line in
                    Text("☐ \(line)").font(.caption).lineLimit(1)
                }
            }
            Button("刷新") {
                Task {
                    await appState.eventKit.requestAccessIfNeeded()
                }
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .onAppear {
            Task { await appState.eventKit.requestAccessIfNeeded() }
        }
    }
}
