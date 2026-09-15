import SwiftUI

struct EventKitSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("今天")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(appState.eventKit.statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if appState.eventKit.events.isEmpty && appState.eventKit.reminders.isEmpty {
                Text("暂无事项（或未授权）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appState.eventKit.events, id: \.self) { line in
                    Text(line).font(.caption).lineLimit(1)
                }
                ForEach(appState.eventKit.reminders, id: \.self) { line in
                    Text("☐ \(line)").font(.caption).lineLimit(1)
                }
            }
            Button("刷新 / 请求权限") {
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
