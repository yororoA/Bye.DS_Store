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

    let settings: AppSettings

    private let finderFolderProvider = FinderFolderProvider()
    private let cleanupWorker = CleanupWorker()
    private var tracker = FolderTracker()
    private var monitoringTask: Task<Void, Never>?

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        refreshLaunchAtLoginState()

        // #region debug-point H4:startup
        debugReport(
            hypothesisId: "H4",
            location: "SweeperAppModel.init",
            message: "[DEBUG] application model initialized",
            data: [
                "bundlePath": Bundle.main.bundleURL.path,
                "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                "processID": ProcessInfo.processInfo.processIdentifier,
                "monitoringEnabled": settings.isMonitoringEnabled
            ]
        )
        // #endregion

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

        // #region debug-point H1:polling-start
        debugReport(
            hypothesisId: "H1",
            location: "SweeperAppModel.start",
            message: "[DEBUG] monitoring task started",
            data: [
                "pollingInterval": settings.pollingInterval,
                "gracePeriod": settings.gracePeriod,
                "monitoringEnabled": settings.isMonitoringEnabled
            ]
        )
        // #endregion

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

        // #region debug-point H1:poll-entry
        debugReport(
            hypothesisId: "H1",
            location: "SweeperAppModel.poll",
            message: "[DEBUG] polling cycle entered",
            data: [
                "monitoringEnabled": settings.isMonitoringEnabled,
                "trackedFolderCount": trackedFolders.count
            ]
        )
        // #endregion

        isPolling = true
        defer {
            isPolling = false
            lastScanDate = Date()

            // #region debug-point H1:poll-exit
            debugReport(
                hypothesisId: "H1",
                location: "SweeperAppModel.poll",
                message: "[DEBUG] polling cycle exited",
                data: [
                    "trackedFolderCount": trackedFolders.count,
                    "lastScanDate": lastScanDate?.timeIntervalSince1970 ?? 0
                ]
            )
            // #endregion
        }

        do {
            let openFolderURLs = try await finderFolderProvider.openFolderURLs()

            // #region debug-point H3:finder-result
            debugReport(
                hypothesisId: "H3",
                location: "FinderFolderProvider.openFolderURLs",
                message: "[DEBUG] Finder query succeeded",
                data: [
                    "folderCount": openFolderURLs.count,
                    "folderPaths": openFolderURLs.map(\.path).sorted()
                ]
            )
            // #endregion

            let now = Date()
            let previouslyTrackedFolderURLs = tracker.trackedFolders.map(\.url)

            trackedFolders = tracker.update(
                openFolderURLs: openFolderURLs,
                at: now,
                gracePeriod: settings.gracePeriod
            )
            finderAccessState = .allowed

            // #region debug-point H5:tracker-state
            debugReport(
                hypothesisId: "H5",
                location: "SweeperAppModel.poll",
                message: "[DEBUG] tracker state updated",
                data: [
                    "openFolderCount": openFolderCount,
                    "gracePeriodFolderCount": gracePeriodFolderCount,
                    "trackedPaths": trackedFolders.map(\.url.path)
                ]
            )
            // #endregion

            let folderURLsForCleanup = Set(
                previouslyTrackedFolderURLs + trackedFolders.map(\.url)
            )
            let cleanupReport = await cleanupWorker.clean(
                folderURLs: Array(folderURLsForCleanup)
            )

            // #region debug-point H5:cleanup-result
            debugReport(
                hypothesisId: "H5",
                location: "CleanupWorker.clean",
                message: "[DEBUG] cleanup completed",
                data: [
                    "folderCount": folderURLsForCleanup.count,
                    "removedCount": cleanupReport.removedFileURLs.count,
                    "failureCount": cleanupReport.failures.count
                ]
            )
            // #endregion

            totalRemovedCount += cleanupReport.removedFileURLs.count
            lastCleanupError = cleanupReport.failures.first.map { failure in
                "\(failure.folderURL.path): \(failure.message)"
            }
        } catch FinderFolderProviderError.automationDenied(let message) {
            // #region debug-point H2:automation-denied
            debugReport(
                hypothesisId: "H2",
                location: "FinderFolderProvider.openFolderURLs",
                message: "[DEBUG] Finder automation permission denied",
                data: ["error": message]
            )
            // #endregion
            finderAccessState = .denied(message)
        } catch {
            // #region debug-point H2:finder-error
            debugReport(
                hypothesisId: "H2",
                location: "FinderFolderProvider.openFolderURLs",
                message: "[DEBUG] Finder query failed",
                data: ["error": error.localizedDescription]
            )
            // #endregion
            finderAccessState = .failed(error.localizedDescription)
        }
    }

    // #region debug-point H1:debug-reporter
    private func debugReport(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:]
    ) {
        var endpoint = "http://127.0.0.1:7777/event"
        var sessionID = "finder-folder-undetected"
        let environmentURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".dbg/finder-folder-undetected.env")

        if let environment = try? String(contentsOf: environmentURL, encoding: .utf8) {
            for line in environment.split(separator: "\n") {
                let components = line.split(separator: "=", maxSplits: 1).map(String.init)
                guard components.count == 2 else {
                    continue
                }

                if components[0] == "DEBUG_SERVER_URL" {
                    endpoint = components[1]
                } else if components[0] == "DEBUG_SESSION_ID" {
                    sessionID = components[1]
                }
            }
        }

        guard let url = URL(string: endpoint) else {
            return
        }

        let payload: [String: Any] = [
            "sessionId": sessionID,
            "runId": "post-fix",
            "hypothesisId": hypothesisId,
            "location": location,
            "msg": message,
            "data": data
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        URLSession.shared.dataTask(with: request).resume()
    }
    // #endregion
}
