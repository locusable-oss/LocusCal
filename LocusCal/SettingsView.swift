import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("显示") {
                Toggle("显示农历日注", isOn: Binding(
                    get: { appState.preferences.showLunar },
                    set: { appState.preferences.showLunar = $0 }
                ))
                Toggle("周起始为周一", isOn: Binding(
                    get: { appState.preferences.weekStartsOnMonday },
                    set: { appState.preferences.weekStartsOnMonday = $0 }
                ))
                Toggle("菜单栏显示日期", isOn: Binding(
                    get: { appState.preferences.menuBarShowsDate },
                    set: { appState.preferences.menuBarShowsDate = $0 }
                ))
                Toggle("菜单栏显示休/班", isOn: Binding(
                    get: { appState.preferences.menuBarShowsHoliday },
                    set: { appState.preferences.menuBarShowsHoliday = $0 }
                ))
            }
            Section("系统") {
                Toggle("登录时启动", isOn: Binding(
                    get: { appState.preferences.launchAtLogin },
                    set: { appState.preferences.launchAtLogin = $0 }
                ))
                Toggle("显示系统日历与提醒（只读）", isOn: Binding(
                    get: { appState.preferences.showEventKit },
                    set: { enabled in
                        appState.preferences.showEventKit = enabled
                        if enabled {
                            Task { await appState.eventKit.requestAccessIfNeeded() }
                        }
                    }
                ))
            }
            Section("节假日数据") {
                Text("嵌入 2025–2027 年国务院放假安排级数据；缺年则格子无标注，不阻断使用。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
