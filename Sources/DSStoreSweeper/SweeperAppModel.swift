import AppKit
import Combine
import Foundation
import ServiceManagement
import SweeperCore

enum FinderAccessState: Equatable {
    case unknown
    case allowed
    case denied(String)
    case failed(String)
}

actor CleanupWorker {
    private let cleaner = DSStoreCleaner()

    func clean(folderURLs: [URL]) -> CleanupReport {
        cleaner.clean(folderURLs: folderURLs)
    }
}

@MainActor
final class SweeperAppModel: ObservableObject {
    @Published private(set) var trackedFolders: [TrackedFolder] = []
    @Published private(set) var finderAccessState: FinderAccessState = .unknown
    @Published private(set) var isPolling = false
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var lastCleanupError: String?
    @Published private(set) var totalRemovedCount = 0
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var launchAtLoginError: String?
    @Published private(set) var isFullDiskScanRunning = false
    @Published private(set) var fullDiskScanReport: FullDiskCleanupReport?

    let settings: AppSettings

    private let finderFolderProvider = FinderFolderProvider()
    private let cleanupWorker = CleanupWorker()
    private let cleanupTargetResolver = CleanupTargetResolver()
    private let fullDiskScanner = FullDiskScanner()
    private var tracker = FolderTracker()
    private var monitoringTask: Task<Void, Never>?
    private var fullDiskScanTask: Task<Void, Never>?

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        refreshLaunchAtLoginState()

        Task { @MainActor [weak self] in
            self?.start()
        }
    }

    var openFolderCount: Int {
        trackedFolders.reduce(into: 0) { count, folder in
            if case .open = folder.state {
                count += 1
            }
        }
    }

    var gracePeriodFolderCount: Int {
        trackedFolders.count - openFolderCount
    }

    func start() {
        guard monitoringTask == nil else {
            return
        }

        monitoringTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                if self.settings.isMonitoringEnabled {
                    await self.poll()
                }

                let sleepInterval = self.settings.isMonitoringEnabled
                    ? self.settings.pollingInterval
                    : 1

                do {
                    try await Task.sleep(for: .seconds(sleepInterval))
                } catch {
                    return
                }
            }
        }
    }

    func pollNow() {
        Task { @MainActor [weak self] in
            await self?.poll()
        }
    }

    func startFullDiskScan() {
        guard !isFullDiskScanRunning else {
            return
        }

        fullDiskScanReport = nil
        isFullDiskScanRunning = true

        fullDiskScanTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let exclusions = self.settings.excludedFolderPatterns.compactMap(
                FolderExclusionPattern.init
            )
            let report = await self.fullDiskScanner.scanAndClean(
                excluding: exclusions
            )
            self.fullDiskScanReport = report
            self.isFullDiskScanRunning = false
            self.fullDiskScanTask = nil
        }
    }

    func cancelFullDiskScan() {
        fullDiskScanTask?.cancel()
    }

    func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }

        refreshLaunchAtLoginState()
    }

    func refreshLaunchAtLoginState() {
        let status = SMAppService.mainApp.status
        launchAtLoginEnabled = status == .enabled || status == .requiresApproval
    }

    func openAutomationPrivacySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func openFolder(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func poll() async {
        guard !isPolling else {
            return
        }

        isPolling = true
        defer {
            isPolling = false
            lastScanDate = Date()
        }

        do {
            let openFolderURLs = try await finderFolderProvider.openFolderURLs()

            let now = Date()
            let previouslyTrackedFolderURLs = tracker.trackedFolders.map(\.url)

            trackedFolders = tracker.update(
                openFolderURLs: openFolderURLs,
                at: now,
                gracePeriod: settings.gracePeriod
            )
            finderAccessState = .allowed

            let folderURLsForCleanup = cleanupTargetResolver.resolve(
                folderURLs: previouslyTrackedFolderURLs + trackedFolders.map(\.url),
                scope: settings.cleanupScope
            )
            let cleanupReport = await cleanupWorker.clean(
                folderURLs: folderURLsForCleanup
            )

            totalRemovedCount += cleanupReport.removedFileURLs.count
            lastCleanupError = cleanupReport.failures.first.map { failure in
                "\(failure.folderURL.path): \(failure.message)"
            }
        } catch FinderFolderProviderError.automationDenied(let message) {
            finderAccessState = .denied(message)
        } catch {
            finderAccessState = .failed(error.localizedDescription)
        }
    }
}
