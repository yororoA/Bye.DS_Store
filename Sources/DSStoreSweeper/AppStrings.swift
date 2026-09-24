import Foundation
import SweeperCore

enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case chinese
    case english

    @MainActor
    func title(using language: AppLanguage) -> String {
        switch self {
        case .system:
            return AppStrings.text("跟随系统", "System default", language: language)
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
}

@MainActor
enum AppStrings {
    static var preferredLanguage: AppLanguage = .system

    @MainActor
    static func isEnglish(for language: AppLanguage? = nil) -> Bool {
        switch language ?? preferredLanguage {
        case .system:
            return Locale.current.language.languageCode?.identifier == "en"
        case .chinese:
            return false
        case .english:
            return true
        }
    }

    static func text(
        _ chinese: String,
        _ english: String,
        language: AppLanguage? = nil
    ) -> String {
        isEnglish(for: language) ? english : chinese
    }

    static var monitoringEnabled: String {
        text("后台监控已开启", "Monitoring enabled")
    }

    static var monitoringPaused: String {
        text("后台监控已暂停", "Monitoring paused")
    }

    static var monitoringLabel: String {
        text("后台监控", "Monitoring")
    }

    static var emptyFolders: String {
        text("Finder 中没有打开的文件夹", "No folders are open in Finder")
    }

    static var immediateScan: String {
        text("立即扫描", "Scan now")
    }

    static var settings: String {
        text("设置", "Settings")
    }

    static var quit: String {
        text("退出", "Quit")
    }

    static var fullDiskScan: String {
        text("扫描本机并清理", "Scan and clean disk")
    }

    static var stopScan: String {
        text("停止本机扫描", "Stop disk scan")
    }

    static var scanInProgress: String {
        text("正在扫描本机...", "Scanning disk...")
    }

    static var shortcut: String {
        "⌘⌥B"
    }

    static func monitored(
        _ openCount: Int,
        _ graceCount: Int,
        language: AppLanguage? = nil
    ) -> String {
        if isEnglish(for: language) {
            if graceCount == 0 {
                return "Monitoring \(openCount) folder\(openCount == 1 ? "" : "s")"
            }
            return "Monitoring \(openCount), cleaning \(graceCount) recently active"
        }

        if graceCount == 0 {
            return "正在监控 \(openCount) 个文件夹"
        }
        return "监控 \(openCount) 个，延续清理 \(graceCount) 个"
    }

    static func recentCleanup(
        _ count: Int,
        language: AppLanguage? = nil
    ) -> String {
        isEnglish(for: language) ? "Last cleanup: \(count)" : "最近清理 \(count) 个"
    }

    static func totalCleanup(
        _ count: Int,
        language: AppLanguage? = nil
    ) -> String {
        isEnglish(for: language) ? "Total cleaned: \(count)" : "累计清理 \(count) 个"
    }

    static func duration(
        _ interval: TimeInterval,
        language: AppLanguage? = nil
    ) -> String {
        let seconds = Int(interval)
        if seconds < 60 {
            return isEnglish(for: language) ? "\(seconds) sec" : "\(seconds) 秒"
        }
        let minutes = seconds / 60
        return isEnglish(for: language) ? "\(minutes) min" : "\(minutes) 分钟"
    }

    static func remaining(
        _ seconds: Int,
        language: AppLanguage? = nil
    ) -> String {
        isEnglish(for: language) ? "\(seconds) sec" : "\(seconds) 秒"
    }

    static func scanScopeTitle(
        _ scope: DiskScanScope,
        language: AppLanguage? = nil
    ) -> String {
        switch scope {
        case .startupDisk:
            return text("仅启动磁盘", "Startup disk only", language: language)
        case .externalDisks:
            return text("启动磁盘和外接磁盘", "Startup and external disks", language: language)
        case .networkDisks:
            return text("启动磁盘和网络磁盘", "Startup and network disks", language: language)
        case .allMountedVolumes:
            return text("所有已挂载磁盘", "All mounted volumes", language: language)
        }
    }

    static func cleanupScopeTitle(
        _ scope: CleanupScope,
        language: AppLanguage? = nil
    ) -> String {
        switch scope {
        case .monitoredAndParent:
            return text("被监控文件夹及其父文件夹", "Monitored folder and parent", language: language)
        case .monitoredOnly:
            return text("仅被监控文件夹", "Monitored folder only", language: language)
        }
    }
}
