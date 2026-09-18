import SwiftUI

struct EventKitSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("今天")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Button("刷新") {
                    Task { await appState.eventKit.requestAccessIfNeeded() }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .disabled(appState.eventKit.isRefreshing)
                .accessibilityLabel("刷新今天的事项")
            }
            if appState.eventKit.events.isEmpty && appState.eventKit.reminders.isEmpty {
                if appState.eventKit.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("正在读取今天的事项")
                } else {
                    Text("暂无事项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(appState.eventKit.events.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.caption).lineLimit(1)
                }
                ForEach(Array(appState.eventKit.reminders.enumerated()), id: \.offset) { _, line in
                    Text("☐ \(line)").font(.caption).lineLimit(1)
                }
            }
        }
        .onAppear {
            Task { await appState.eventKit.requestAccessIfNeeded() }
        }
    }
}
