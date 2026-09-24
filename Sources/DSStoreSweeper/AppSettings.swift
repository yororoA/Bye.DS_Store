import Combine
import Foundation
import SweeperCore

@MainActor
final class AppSettings: ObservableObject {
    static let pollingIntervals: [TimeInterval] = [2, 5, 10, 30, 60]
    static let gracePeriods: [TimeInterval] = [15, 30, 60, 120, 300]
    static let defaultExcludedFolderPatterns = [
        "node_modules",
        ".venv",
        "venv",
        "__pycache__",
        "vendor",
        "Pods",
        "target",
        ".gradle"
    ]

    private enum Key {
        static let isMonitoringEnabled = "isMonitoringEnabled"
        static let pollingInterval = "pollingInterval"
        static let gracePeriod = "gracePeriod"
        static let cleanupScope = "cleanupScope"
        static let excludedFolderPatterns = "excludedFolderPatterns"
        static let diskScanScope = "diskScanScope"
        static let language = "language"
    }

    @Published var isMonitoringEnabled: Bool {
        didSet {
            defaults.set(isMonitoringEnabled, forKey: Key.isMonitoringEnabled)
        }
    }

    @Published var pollingInterval: TimeInterval {
        didSet {
            defaults.set(pollingInterval, forKey: Key.pollingInterval)
        }
    }

    @Published var gracePeriod: TimeInterval {
        didSet {
            defaults.set(gracePeriod, forKey: Key.gracePeriod)
        }
    }

    @Published var cleanupScope: CleanupScope {
        didSet {
            defaults.set(cleanupScope.rawValue, forKey: Key.cleanupScope)
        }
    }

    @Published var excludedFolderPatterns: [String] {
        didSet {
            defaults.set(excludedFolderPatterns, forKey: Key.excludedFolderPatterns)
        }
    }

    @Published var diskScanScope: DiskScanScope {
        didSet {
            defaults.set(diskScanScope.rawValue, forKey: Key.diskScanScope)
        }
    }

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Key.language)
            AppStrings.preferredLanguage = language
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.isMonitoringEnabled) == nil {
            isMonitoringEnabled = true
        } else {
            isMonitoringEnabled = defaults.bool(forKey: Key.isMonitoringEnabled)
        }

        let storedPollingInterval = defaults.double(forKey: Key.pollingInterval)
        pollingInterval = Self.pollingIntervals.contains(storedPollingInterval)
            ? storedPollingInterval
            : 5

        let storedGracePeriod = defaults.double(forKey: Key.gracePeriod)
        gracePeriod = Self.gracePeriods.contains(storedGracePeriod)
            ? storedGracePeriod
            : 60

        cleanupScope = CleanupScope(
            rawValue: defaults.string(forKey: Key.cleanupScope) ?? ""
        ) ?? .monitoredAndParent

        let storedExcludedFolderPatterns = defaults.array(
            forKey: Key.excludedFolderPatterns
        ) as? [String]
        excludedFolderPatterns = (storedExcludedFolderPatterns ?? Self.defaultExcludedFolderPatterns)
            .compactMap { FolderExclusionPattern($0)?.value }

        diskScanScope = DiskScanScope(
            rawValue: defaults.string(forKey: Key.diskScanScope) ?? ""
        ) ?? .startupDisk

        language = AppLanguage(
            rawValue: defaults.string(forKey: Key.language) ?? ""
        ) ?? .system
        AppStrings.preferredLanguage = language
    }

    @discardableResult
    func addExcludedFolderPattern(_ input: String) -> Bool {
        guard let pattern = FolderExclusionPattern(input) else {
            return false
        }

        let isDuplicate = excludedFolderPatterns.contains {
            $0.caseInsensitiveCompare(pattern.value) == .orderedSame
        }
        guard !isDuplicate else {
            return false
        }

        excludedFolderPatterns.append(pattern.value)
        return true
    }

    func removeExcludedFolderPattern(_ pattern: String) {
        excludedFolderPatterns.removeAll { $0 == pattern }
    }

    func resetExcludedFolderPatterns() {
        excludedFolderPatterns = Self.defaultExcludedFolderPatterns
    }

    func removeAllExcludedFolderPatterns() {
        excludedFolderPatterns = []
    }
}
