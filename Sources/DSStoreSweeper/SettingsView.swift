import SwiftUI
import SweeperCore

struct SettingsView: View {
    @ObservedObject var model: SweeperAppModel
    @ObservedObject private var settings: AppSettings
    @State private var exclusionInput = ""
    @State private var exclusionInputError = false
    @State private var isShowingFullDiskScanConfirmation = false
    @State private var isShowingFullDiskScanDetails = false

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
                        isShowingFullDiskScanConfirmation = true
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

                    Button("查看扫描详情") {
                        isShowingFullDiskScanDetails = true
                    }
                }
            }

            Section("扫描排除") {
                Text("输入文件夹名称，或输入“父文件夹/目标文件夹”路径。全盘扫描遇到匹配的文件夹时会跳过整个目录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    TextField("例如 node_modules 或 lib/packages", text: $exclusionInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addExclusionPattern)

                    Button(action: addExclusionPattern) {
                        Image(systemName: "plus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.borderless)
                    .disabled(exclusionInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("添加排除规则")
                    .accessibilityLabel("添加排除规则")
                }

                if exclusionInputError {
                    Text("请输入有效的文件夹名称或路径，例如 node_modules、lib/packages。")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(settings.excludedFolderPatterns, id: \.self) { pattern in
                        ExclusionTag(pattern: pattern) {
                            settings.removeExcludedFolderPattern(pattern)
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
        .frame(width: 640, height: 720)
        .onAppear {
            model.refreshLaunchAtLoginState()
        }
        .alert(
            "扫描整个启动磁盘？",
            isPresented: $isShowingFullDiskScanConfirmation
        ) {
            Button("扫描并清理", role: .destructive) {
                model.startFullDiskScan()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将递归扫描启动磁盘中的 .DS_Store 并直接删除。扫描可能耗时较长，也可能需要完整磁盘访问权限。")
        }
        .sheet(isPresented: $isShowingFullDiskScanDetails) {
            if let report = model.fullDiskScanReport {
                FullDiskScanDetailView(report: report)
            }
        }
    }

    private func addExclusionPattern() {
        let didAdd = settings.addExcludedFolderPattern(exclusionInput)
        exclusionInputError = !didAdd && !exclusionInput.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty

        if didAdd {
            exclusionInput = ""
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

private struct FullDiskScanDetailView: View {
    let report: FullDiskCleanupReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(
                    report.wasCancelled ? "扫描已停止" : "扫描完成",
                    systemImage: report.wasCancelled
                        ? "stop.circle"
                        : "checkmark.circle.fill"
                )
                .font(.title3.weight(.semibold))
                .foregroundStyle(report.wasCancelled ? .orange : .green)

                Spacer()

                Button("完成") {
                    dismiss()
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 8) {
                GridRow {
                    Text("扫描项目").foregroundStyle(.secondary)
                    Text("\(report.scannedItemCount)")
                }
                GridRow {
                    Text("发现 .DS_Store").foregroundStyle(.secondary)
                    Text("\(report.foundDSStoreCount)")
                }
                GridRow {
                    Text("已删除").foregroundStyle(.secondary)
                    Text("\(report.removedDSStoreCount)")
                }
                GridRow {
                    Text("失败项目").foregroundStyle(.secondary)
                    Text("\(report.failureCount)")
                }
            }

            Divider()

            Text("失败列表")
                .font(.headline)

            if report.failures.isEmpty {
                Label("没有记录到失败项目", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(report.failures.enumerated()), id: \.offset) { _, failure in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(failure.fileURL.path)
                                    .font(.caption)
                                    .textSelection(.enabled)
                                Text(failure.message)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()
                        }
                    }
                }
            }

            if report.failureCount > report.failures.count {
                Text("仅显示前 \(report.failures.count) 条失败记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 620, height: 520)
    }
}

private struct ExclusionTag: View {
    let pattern: String
    let removeAction: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(pattern)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)

            Button(action: removeAction) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("移除 \(pattern)")
            .accessibilityLabel("移除 \(pattern)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
}
