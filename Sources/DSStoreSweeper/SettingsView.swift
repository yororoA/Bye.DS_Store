import SwiftUI
import SweeperCore

struct SettingsView: View {
    @ObservedObject var model: SweeperAppModel
    @ObservedObject private var settings: AppSettings
    @State private var exclusionInput = ""
    @State private var exclusionInputError = false
    @State private var isShowingFullDiskScanConfirmation = false
    @State private var isShowingFullDiskScanDetails = false
    @State private var isShowingClearExclusionsConfirmation = false

    init(model: SweeperAppModel) {
        self.model = model
        settings = model.settings
    }

    var body: some View {
        Form {
            Section(AppStrings.text("监控", "Monitoring")) {
                Toggle(
                    AppStrings.text("启用后台监控", "Enable background monitoring"),
                    isOn: $settings.isMonitoringEnabled
                )

                Picker(
                    AppStrings.text("扫描间隔", "Polling interval"),
                    selection: $settings.pollingInterval
                ) {
                    ForEach(AppSettings.pollingIntervals, id: \.self) { interval in
                        Text(AppStrings.duration(interval))
                            .tag(interval)
                    }
                }

                Picker(
                    AppStrings.text("文件夹关闭后继续清理", "Cleanup grace period"),
                    selection: $settings.gracePeriod
                ) {
                    ForEach(AppSettings.gracePeriods, id: \.self) { interval in
                        Text(AppStrings.duration(interval))
                            .tag(interval)
                    }
                }

                Picker(
                    AppStrings.text("清理范围", "Cleanup scope"),
                    selection: $settings.cleanupScope
                ) {
                    ForEach(CleanupScope.allCases, id: \.self) { scope in
                        Text(AppStrings.cleanupScopeTitle(scope))
                            .tag(scope)
                    }
                }

                Picker(
                    AppStrings.text("界面语言", "Interface language"),
                    selection: $settings.language
                ) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.title(using: settings.language))
                            .tag(language)
                    }
                }

                Text(AppStrings.text(
                    "经实机排查，.DS_Store 不会直接生成在被打开文件夹的根目录，而是主要在进入其子文件夹时生成在原目录。",
                    "In testing, .DS_Store was usually created in the original folder when entering one of its child folders, rather than directly in the opened folder."
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(AppStrings.text("本机扫描", "Disk scan")) {
                Text(AppStrings.text(
                    "手动递归扫描磁盘中的 .DS_Store。扫描可能耗时较长，并可能需要在系统设置中授予完整磁盘访问权限。",
                    "Manually scan the selected disks for .DS_Store files. This may take a while and may require Full Disk Access."
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Picker(
                    AppStrings.text("扫描位置", "Scan locations"),
                    selection: $settings.diskScanScope
                ) {
                    ForEach(DiskScanScope.allCases, id: \.self) { scope in
                        Text(AppStrings.scanScopeTitle(scope))
                            .tag(scope)
                    }
                }

                if model.isFullDiskScanRunning {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text(AppStrings.scanInProgress)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(AppStrings.text("停止", "Stop")) {
                            model.cancelFullDiskScan()
                        }
                    }
                } else {
                    Button {
                        isShowingFullDiskScanConfirmation = true
                    } label: {
                        Label(AppStrings.fullDiskScan, systemImage: "magnifyingglass")
                    }
                }

                if let report = model.fullDiskScanReport {
                    LabeledContent(
                        report.wasCancelled
                            ? AppStrings.text("扫描状态", "Scan status")
                            : AppStrings.text("扫描完成", "Scan complete"),
                        value: report.wasCancelled
                            ? AppStrings.text("已停止", "Stopped")
                            : AppStrings.text("已完成", "Complete")
                    )
                    LabeledContent(
                        AppStrings.text("扫描项目", "Items scanned"),
                        value: "\(report.scannedItemCount)"
                    )
                    LabeledContent(
                        AppStrings.text("发现 .DS_Store", "Found .DS_Store"),
                        value: "\(report.foundDSStoreCount)"
                    )
                    LabeledContent(
                        AppStrings.text("已删除", "Removed"),
                        value: "\(report.removedDSStoreCount)"
                    )

                    if report.failureCount > 0 {
                        Label(
                            AppStrings.failureSummary(
                                report.failureCount,
                                language: settings.language
                            ),
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

                    Button(AppStrings.text("查看扫描详情", "View scan details")) {
                        isShowingFullDiskScanDetails = true
                    }
                }
            }

            Section(AppStrings.text("扫描排除", "Scan exclusions")) {
                Text(AppStrings.text(
                    "输入文件夹名称，或输入“父文件夹/目标文件夹”路径。全盘扫描遇到匹配的文件夹时会跳过整个目录。",
                    "Enter a folder name or a parent/target path. Full-disk scans skip matching folders and all descendants."
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    TextField(
                        AppStrings.text("例如 node_modules 或 lib/packages", "e.g. node_modules or lib/packages"),
                        text: $exclusionInput
                    )
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addExclusionPattern)

                    Button(action: addExclusionPattern) {
                        Image(systemName: "plus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.borderless)
                    .disabled(exclusionInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help(AppStrings.text("添加排除规则", "Add exclusion"))
                    .accessibilityLabel(AppStrings.text("添加排除规则", "Add exclusion"))
                }

                if exclusionInputError {
                    Text(AppStrings.text(
                        "请输入有效的文件夹名称或路径，例如 node_modules、lib/packages。",
                        "Enter a valid folder name or path, such as node_modules or lib/packages."
                    ))
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

                HStack {
                    Button(AppStrings.text("恢复默认规则", "Restore defaults")) {
                        settings.resetExcludedFolderPatterns()
                    }
                    .disabled(settings.excludedFolderPatterns == AppSettings.defaultExcludedFolderPatterns)

                    Spacer()

                    Button(AppStrings.text("清空全部", "Clear all"), role: .destructive) {
                        isShowingClearExclusionsConfirmation = true
                    }
                    .disabled(settings.excludedFolderPatterns.isEmpty)
                }
            }

            Section(AppStrings.text("系统", "System")) {
                Toggle(
                    AppStrings.text("登录时启动", "Launch at login"),
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

            Section(AppStrings.text("统计", "Statistics")) {
                LabeledContent(
                    AppStrings.text("当前打开", "Currently open"),
                    value: "\(model.openFolderCount)"
                )
                LabeledContent(
                    AppStrings.text("延续清理", "Grace-period folders"),
                    value: "\(model.gracePeriodFolderCount)"
                )
                LabeledContent(
                    AppStrings.text("本次运行已删除", "Removed this run"),
                    value: "\(model.totalRemovedCount)"
                )
            }
        }
        .formStyle(.grouped)
        .id(settings.language)
        .frame(width: 640, height: 720)
        .onAppear {
            model.refreshLaunchAtLoginState()
        }
        .alert(
            AppStrings.text("扫描整个磁盘？", "Scan the selected disks?"),
            isPresented: $isShowingFullDiskScanConfirmation
        ) {
            Button(AppStrings.text("扫描并清理", "Scan and clean"), role: .destructive) {
                model.startFullDiskScan()
            }
            Button(AppStrings.text("取消", "Cancel"), role: .cancel) {}
        } message: {
            Text(AppStrings.text(
                "将递归扫描所选磁盘中的 .DS_Store 并直接删除。扫描可能耗时较长，也可能需要完整磁盘访问权限。",
                "This recursively scans and permanently deletes .DS_Store files on the selected disks. It may take a while and may require Full Disk Access."
            ))
        }
        .alert(
            AppStrings.text("清空全部排除规则？", "Clear all exclusion rules?"),
            isPresented: $isShowingClearExclusionsConfirmation
        ) {
            Button(AppStrings.text("清空", "Clear"), role: .destructive) {
                settings.removeAllExcludedFolderPatterns()
            }
            Button(AppStrings.text("取消", "Cancel"), role: .cancel) {}
        } message: {
            Text(AppStrings.text(
                "全盘扫描将不再跳过任何已配置的文件夹。",
                "Full-disk scans will no longer skip any configured folders."
            ))
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
            LabeledContent(
                AppStrings.text("Finder 权限", "Finder permission"),
                value: AppStrings.text("等待检测", "Waiting to check")
            )
        case .allowed:
            LabeledContent(AppStrings.text("Finder 权限", "Finder permission")) {
                Label(AppStrings.text("已授权", "Allowed"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .denied:
            LabeledContent(AppStrings.text("Finder 权限", "Finder permission")) {
                Button(AppStrings.text("打开系统设置", "Open System Settings")) {
                    model.openAutomationPrivacySettings()
                }
            }
        case .failed(let message):
            LabeledContent(AppStrings.text("Finder 状态", "Finder status")) {
                Text(message)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }
        }
    }
}

private struct FullDiskScanDetailView: View {
    let report: FullDiskCleanupReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
            Label(
                    report.wasCancelled
                        ? AppStrings.text("扫描已停止", "Scan stopped")
                        : AppStrings.text("扫描完成", "Scan complete"),
                    systemImage: report.wasCancelled
                        ? "stop.circle"
                        : "checkmark.circle.fill"
                )
                .font(.title3.weight(.semibold))
                .foregroundStyle(report.wasCancelled ? .orange : .green)

                Spacer()

                Button(AppStrings.text("完成", "Done")) {
                    dismiss()
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 8) {
                GridRow {
                    Text(AppStrings.text("扫描项目", "Items scanned"))
                        .foregroundStyle(.secondary)
                    Text("\(report.scannedItemCount)")
                }
                GridRow {
                    Text(AppStrings.text("发现 .DS_Store", "Found .DS_Store"))
                        .foregroundStyle(.secondary)
                    Text("\(report.foundDSStoreCount)")
                }
                GridRow {
                    Text(AppStrings.text("已删除", "Removed"))
                        .foregroundStyle(.secondary)
                    Text("\(report.removedDSStoreCount)")
                }
                GridRow {
                    Text(AppStrings.text("失败项目", "Failed items"))
                        .foregroundStyle(.secondary)
                    Text("\(report.failureCount)")
                }
            }

            Divider()

            Text(AppStrings.text("失败列表", "Failures"))
                .font(.headline)

            if report.failures.isEmpty {
                Label(
                    AppStrings.text("没有记录到失败项目", "No failures recorded"),
                    systemImage: "checkmark.circle"
                )
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
                Text(AppStrings.failureRecordsSummary(
                    report.failures.count
                ))
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
