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
    @Published private(set) var lastCleanupDate: Date?
    @Published private(set) var lastCleanupRemovedCount = 0
    @Published private(set) var lastCleanupError: String?
    @Published private(set) var totalRemovedCount = 0
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var launchAtLoginError: String?
    @Published private(set) var isFullDiskScanRunning = false
    @Published private(set) var fullDiskScanReport: FullDiskCleanupReport?
    @Published private(set) var updateState: AppUpdateState = .idle

    let settings: AppSettings

    private let finderFolderProvider = FinderFolderProvider()
    private let cleanupWorker = CleanupWorker()
    private let cleanupTargetResolver = CleanupTargetResolver()
    private let fullDiskScanner = FullDiskScanner()
    private let mountedVolumeResolver = MountedVolumeResolver()
    private let updateClient = AppUpdateClient()
    private let pollingPolicy = AdaptivePollingPolicy()
    private var tracker = FolderTracker()
    private var monitoringTask: Task<Void, Never>?
    private var consecutiveIdlePolls = 0
    private var fullDiskScanTask: Task<Void, Never>?
    private var updateScheduleTask: Task<Void, Never>?
    private var updateRequestTask: Task<Void, Never>?
    private var updateDownloadTask: Task<Void, Never>?
    private var updateInstallTask: Task<Void, Never>?
    private var downloadedInstallerURL: URL?
    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        refreshLaunchAtLoginState()
        configureMonitoring()
        configureAutomaticUpdateChecks()
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
        guard monitoringTask == nil,
              settings.isMonitoringEnabled else {
            return
        }

        monitoringTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                await self.poll()
                let sleepInterval = self.pollingPolicy.interval(
                    baseInterval: self.settings.pollingInterval,
                    consecutiveIdlePolls: self.consecutiveIdlePolls
                )

                do {
                    try await Task.sleep(for: .seconds(sleepInterval))
                } catch {
                    return
                }
            }
        }
    }

    func pollNow() {
        consecutiveIdlePolls = 0
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
                excluding: exclusions,
                skipping: self.mountedVolumeResolver.excludedVolumeURLs(
                    for: self.settings.diskScanScope
                )
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

    var currentAppVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0.0"
    }

    func checkForUpdates() {
        guard updateState != .checking else {
            return
        }

        updateState = .checking
        updateRequestTask?.cancel()
        updateRequestTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                let currentVersion = SemanticVersion(self.currentAppVersion)
                    ?? SemanticVersion("0.0.0")!
                let release = try await self.updateClient.latestRelease(
                    newerThan: currentVersion
                )
                self.updateState = release.map(AppUpdateState.available) ?? .upToDate
            } catch is CancellationError {
                return
            } catch {
                self.updateState = .failed(error.localizedDescription)
            }
        }
    }

    func downloadAndOpenUpdate(_ release: AppUpdateRelease) {
        guard updateDownloadTask == nil else {
            return
        }

        updateState = .downloading(release)
        updateDownloadTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                let installerURL = try await self.updateClient.download(release)
                self.downloadedInstallerURL = installerURL
                self.updateState = .readyToInstall(release)
            } catch is CancellationError {
                return
            } catch {
                self.updateState = .failed(error.localizedDescription)
            }

            self.updateDownloadTask = nil
        }
    }

    func openDownloadedInstaller() {
        guard updateInstallTask == nil,
              let downloadedInstallerURL,
              case .readyToInstall(let release) = updateState else {
            return
        }

        updateState = .installing(release)
        updateInstallTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                let installation = try await self.updateClient.prepareInstallation(
                    for: downloadedInstallerURL,
                    currentBundleURL: Bundle.main.bundleURL,
                    expectedBundleIdentifier: Bundle.main.bundleIdentifier
                        ?? AppUpdateClient.applicationBundleIdentifier
                )
                let processIDs = self.runningApplicationProcessIDs()
                try self.updateClient.launchInstallation(
                    installation,
                    waitingFor: processIDs
                )
                NSApplication.shared.terminate(nil)
            } catch is CancellationError {
                return
            } catch {
                self.updateState = .failed(error.localizedDescription)
            }

            self.updateInstallTask = nil
        }
    }

    private func runningApplicationProcessIDs() -> [Int32] {
        let bundleIdentifier = Bundle.main.bundleIdentifier
            ?? AppUpdateClient.applicationBundleIdentifier
        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        let runningApplications = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)

        for application in runningApplications
            where application.processIdentifier != currentProcessID {
            application.terminate()
        }

        let processIDs = runningApplications.map(\.processIdentifier)
        return Array(Set(processIDs + [currentProcessID]))
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
            consecutiveIdlePolls = trackedFolders.isEmpty
                ? consecutiveIdlePolls + 1
                : 0

            let folderURLsForCleanup = cleanupTargetResolver.resolve(
                folderURLs: previouslyTrackedFolderURLs + trackedFolders.map(\.url),
                scope: settings.cleanupScope
            )
            let cleanupReport = await cleanupWorker.clean(
                folderURLs: folderURLsForCleanup
            )

            lastCleanupDate = Date()
            lastCleanupRemovedCount = cleanupReport.removedFileURLs.count
            totalRemovedCount += cleanupReport.removedFileURLs.count
            lastCleanupError = cleanupReport.failures.first.map { failure in
                "\(failure.folderURL.path): \(failure.message)"
            }
        } catch FinderFolderProviderError.automationDenied(let message) {
            finderAccessState = .denied(message)
            consecutiveIdlePolls += 1
        } catch {
            finderAccessState = .failed(error.localizedDescription)
            consecutiveIdlePolls += 1
        }
    }

    private func configureMonitoring() {
        Publishers.CombineLatest(
            settings.$isMonitoringEnabled.removeDuplicates(),
            settings.$pollingInterval.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _ in
            self?.restartMonitoring()
        }
        .store(in: &cancellables)

        let workspaceNotifications = NSWorkspace.shared.notificationCenter
        for notificationName in [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ] {
            workspaceNotifications.publisher(for: notificationName)
                .compactMap { notification in
                    notification.userInfo?[
                        NSWorkspace.applicationUserInfoKey
                    ] as? NSRunningApplication
                }
                .filter { application in
                    application.bundleIdentifier == "com.apple.finder"
                }
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.wakeMonitoringForFinderActivity()
                }
                .store(in: &cancellables)
        }

        workspaceNotifications.publisher(
            for: NSWorkspace.didWakeNotification
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.wakeMonitoringForFinderActivity()
        }
        .store(in: &cancellables)
    }

    private func restartMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        consecutiveIdlePolls = 0
        start()
    }

    private func wakeMonitoringForFinderActivity() {
        guard settings.isMonitoringEnabled else {
            return
        }

        consecutiveIdlePolls = 0
        guard !isPolling else {
            return
        }

        monitoringTask?.cancel()
        monitoringTask = nil
        start()
    }

    private func configureAutomaticUpdateChecks() {
        settings.$automaticUpdatesEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.restartAutomaticUpdateChecks()
            }
            .store(in: &cancellables)

        restartAutomaticUpdateChecks()
    }

    private func restartAutomaticUpdateChecks() {
        updateScheduleTask?.cancel()
        updateScheduleTask = nil

        guard settings.automaticUpdatesEnabled else {
            updateRequestTask?.cancel()
            updateRequestTask = nil
            if updateState == .checking {
                updateState = .idle
            }
            return
        }

        updateScheduleTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            self.checkForUpdates()

            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(24 * 60 * 60))
                    guard self.settings.automaticUpdatesEnabled else {
                        return
                    }
                    self.checkForUpdates()
                }
            } catch {
                return
            }
        }
    }
}
