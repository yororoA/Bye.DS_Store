import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SweeperAppModel
    @ObservedObject private var settings: AppSettings

    init(model: SweeperAppModel) {
        self.model = model
        settings = model.settings
    }

    var body: some View {
        Form {
            Section("监控") {
                Toggle("启用后台监控", isOn: $settings.isMonitoringEnabled)

                Picker("扫描间隔", selection: $settings.pollingInterval) {
                    ForEach(AppSettings.pollingIntervals, id: \.self) { interval in
                        Text(durationLabel(interval))
                            .tag(interval)
                    }
                }

                Picker("文件夹关闭后继续清理", selection: $settings.gracePeriod) {
                    ForEach(AppSettings.gracePeriods, id: \.self) { interval in
                        Text(durationLabel(interval))
                            .tag(interval)
                    }
                }

                LabeledContent("清理范围", value: "被监控文件夹的根目录")
            }

            Section("系统") {
                Toggle(
                    "登录时启动",
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )

                finderAccessRow

                if let launchAtLoginError = model.launchAtLoginError {
                    Label(launchAtLoginError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let lastCleanupError = model.lastCleanupError {
                    Label(lastCleanupError, systemImage: "externaldrive.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }

            Section("统计") {
                LabeledContent("当前打开", value: "\(model.openFolderCount)")
                LabeledContent("延续清理", value: "\(model.gracePeriodFolderCount)")
                LabeledContent("本次运行已删除", value: "\(model.totalRemovedCount)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 420)
        .onAppear {
            model.refreshLaunchAtLoginState()
        }
    }

    @ViewBuilder
    private var finderAccessRow: some View {
        switch model.finderAccessState {
        case .unknown:
            LabeledContent("Finder 权限", value: "等待检测")
        case .allowed:
            LabeledContent("Finder 权限") {
                Label("已授权", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .denied:
            LabeledContent("Finder 权限") {
                Button("打开系统设置") {
                    model.openAutomationPrivacySettings()
                }
            }
        case .failed(let message):
            LabeledContent("Finder 状态") {
                Text(message)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }
        }
    }

    private func durationLabel(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)

        if seconds < 60 {
            return "\(seconds) 秒"
        }

        let minutes = seconds / 60
        return "\(minutes) 分钟"
    }
}
