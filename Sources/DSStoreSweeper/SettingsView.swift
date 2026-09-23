import SwiftUI
import SweeperCore

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

                Picker("清理范围", selection: $settings.cleanupScope) {
                    ForEach(CleanupScope.allCases, id: \.self) { scope in
                        Text(scope.title)
                            .tag(scope)
                    }
                }

                Text("经实机排查，.DS_Store 不会直接生成在被打开文件夹的根目录，而是主要在进入其子文件夹时生成在原目录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("本机扫描") {
                Text("手动递归扫描整个启动卷中的 .DS_Store。扫描可能耗时较长，并可能需要在系统设置中授予完整磁盘访问权限。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if model.isFullDiskScanRunning {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("正在扫描本机...")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("停止") {
                            model.cancelFullDiskScan()
                        }
                    }
                } else {
                    Button {
                        model.startFullDiskScan()
                    } label: {
                        Label("扫描本机并清理", systemImage: "magnifyingglass")
                    }
                }

                if let report = model.fullDiskScanReport {
                    LabeledContent(
                        report.wasCancelled ? "扫描状态" : "扫描完成",
                        value: report.wasCancelled ? "已停止" : "已完成"
                    )
                    LabeledContent("扫描项目", value: "\(report.scannedItemCount)")
                    LabeledContent("发现 .DS_Store", value: "\(report.foundDSStoreCount)")
                    LabeledContent("已删除", value: "\(report.removedDSStoreCount)")

                    if report.failureCount > 0 {
                        Label(
                            "有 \(report.failureCount) 个项目无法访问或删除",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)

                        if let firstFailure = report.failures.first {
                            Text("\(firstFailure.fileURL.path): \(firstFailure.message)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .textSelection(.enabled)
                        }
                    }
                }
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
        .frame(width: 480, height: 560)
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
