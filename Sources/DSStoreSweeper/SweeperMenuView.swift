import AppKit
import SwiftUI
import SweeperCore

struct SweeperMenuView: View {
    @ObservedObject var model: SweeperAppModel
    @ObservedObject private var settings: AppSettings
    private let onOpenSettings: () -> Void
    @State private var isShowingFullDiskScanConfirmation = false

    init(
        model: SweeperAppModel,
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.model = model
        settings = model.settings
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            status
            Divider()
            folderList
            Divider()
            footer
        }
        .frame(width: 360)
        .alert(
            AppStrings.text(
                "扫描整个启动磁盘？",
                "Scan the startup disk?",
                language: settings.language
            ),
            isPresented: $isShowingFullDiskScanConfirmation
        ) {
            Button(
                AppStrings.text("扫描并清理", "Scan and clean", language: settings.language),
                role: .destructive
            ) {
                model.startFullDiskScan()
            }
            Button(
                AppStrings.text("取消", "Cancel", language: settings.language),
                role: .cancel
            ) {}
        } message: {
            Text(AppStrings.text(
                "将递归扫描启动磁盘中的 .DS_Store 并直接删除。扫描可能耗时较长。",
                "This recursively scans and permanently deletes .DS_Store files on the startup disk. It may take a while.",
                language: settings.language
            ))
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Bye.DS_Store")
                    .font(.headline)

                Text(settings.isMonitoringEnabled
                     ? AppStrings.text("后台监控已开启", "Monitoring enabled", language: settings.language)
                     : AppStrings.text("后台监控已暂停", "Monitoring paused", language: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                AppStrings.text("后台监控", "Monitoring", language: settings.language),
                isOn: $settings.isMonitoringEnabled
            )
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(14)
    }

    @ViewBuilder
    private var status: some View {
        switch model.finderAccessState {
        case .denied(let message):
            issueRow(
                icon: "lock.trianglebadge.exclamationmark",
                title: AppStrings.text(
                    "Finder 自动化权限被拒绝",
                    "Finder automation permission denied",
                    language: settings.language
                ),
                detail: message,
                showsSettingsButton: true
            )
        case .failed(let message):
            issueRow(
                icon: "exclamationmark.triangle",
                title: AppStrings.text(
                    "无法读取 Finder",
                    "Unable to read Finder",
                    language: settings.language
                ),
                detail: message,
                showsSettingsButton: false
            )
        case .unknown, .allowed:
            HStack(spacing: 8) {
                Image(systemName: model.isPolling ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    .foregroundStyle(model.isPolling ? Color.orange : Color.green)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let lastCleanupDate = model.lastCleanupDate {
                        Text(lastCleanupDate, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Text(AppStrings.recentCleanup(
                        model.lastCleanupRemovedCount,
                        language: settings.language
                    ))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private var folderList: some View {
        Group {
            if model.trackedFolders.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text(AppStrings.text(
                        "Finder 中没有打开的文件夹",
                        "No folders are open in Finder",
                        language: settings.language
                    ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 118)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.trackedFolders) { folder in
                            FolderRow(
                                folder: folder,
                                openAction: {
                                    model.openFolder(folder.url)
                                },
                                language: settings.language
                            )

                            if folder.id != model.trackedFolders.last?.id {
                                Divider()
                                    .padding(.leading, 42)
                            }
                        }
                    }
                }
                .frame(minHeight: 118, maxHeight: 260)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AppStrings.totalCleanup(
                    model.totalRemovedCount,
                    language: settings.language
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(
                    AppStrings.text("快捷键 ", "Shortcut ", language: settings.language)
                        + AppStrings.shortcut
                )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                model.pollNow()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .disabled(model.isPolling)
            .help(AppStrings.text("立即扫描", "Scan now", language: settings.language))
            .accessibilityLabel(AppStrings.text("立即扫描", "Scan now", language: settings.language))

            Button {
                if model.isFullDiskScanRunning {
                    model.cancelFullDiskScan()
                } else {
                    isShowingFullDiskScanConfirmation = true
                }
            } label: {
                Image(systemName: model.isFullDiskScanRunning ? "stop.fill" : "magnifyingglass")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(model.isFullDiskScanRunning
                  ? AppStrings.text("停止本机扫描", "Stop disk scan", language: settings.language)
                  : AppStrings.text("扫描本机并清理", "Scan and clean disk", language: settings.language))
            .accessibilityLabel(model.isFullDiskScanRunning
                ? AppStrings.text("停止本机扫描", "Stop disk scan", language: settings.language)
                : AppStrings.text("扫描本机并清理", "Scan and clean disk", language: settings.language))

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(AppStrings.text("设置", "Settings", language: settings.language))
            .accessibilityLabel(AppStrings.text("设置", "Settings", language: settings.language))

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(AppStrings.text("退出", "Quit", language: settings.language))
            .accessibilityLabel(AppStrings.text("退出", "Quit", language: settings.language))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var statusText: String {
        if !settings.isMonitoringEnabled {
            return AppStrings.text("后台监控已暂停", "Monitoring paused", language: settings.language)
        }

        return AppStrings.monitored(
            model.openFolderCount,
            model.gracePeriodFolderCount,
            language: settings.language
        )
    }

    private func issueRow(
        icon: String,
        title: String,
        detail: String,
        showsSettingsButton: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(Color.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            if showsSettingsButton {
                Button(AppStrings.text("授权", "Allow", language: settings.language)) {
                    model.openAutomationPrivacySettings()
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct FolderRow: View {
    let folder: TrackedFolder
    let openAction: () -> Void
    let language: AppLanguage

    var body: some View {
        Button(action: openAction) {
            HStack(spacing: 10) {
                Image(systemName: stateIcon)
                    .foregroundStyle(stateColor)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(folderName)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(folder.url.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                stateLabel
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .help(folder.url.path)
    }

    private var folderName: String {
        let name = folder.url.lastPathComponent
        return name.isEmpty ? "/" : name
    }

    private var stateIcon: String {
        switch folder.state {
        case .open:
            return "folder.fill"
        case .gracePeriod:
            return "clock"
        }
    }

    private var stateColor: Color {
        switch folder.state {
        case .open:
            return .accentColor
        case .gracePeriod:
            return .orange
        }
    }

    @ViewBuilder
    private var stateLabel: some View {
        switch folder.state {
        case .open:
            Text(AppStrings.text("打开", "Open", language: language))
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .gracePeriod(let expiresAt):
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remainingSeconds = max(
                    0,
                    Int(expiresAt.timeIntervalSince(context.date).rounded(.up))
                )

                Text(AppStrings.remaining(remainingSeconds, language: language))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
            }
        }
    }
}
