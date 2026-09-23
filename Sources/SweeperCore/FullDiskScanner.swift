import Foundation

public struct FullDiskScanFailure: Equatable, Sendable {
    public let fileURL: URL
    public let message: String

    public init(fileURL: URL, message: String) {
        self.fileURL = fileURL
        self.message = message
    }
}

public struct FullDiskCleanupReport: Equatable, Sendable {
    public let scannedItemCount: Int
    public let foundDSStoreCount: Int
    public let removedDSStoreCount: Int
    public let failureCount: Int
    public let failures: [FullDiskScanFailure]
    public let wasCancelled: Bool

    public init(
        scannedItemCount: Int,
        foundDSStoreCount: Int,
        removedDSStoreCount: Int,
        failureCount: Int,
        failures: [FullDiskScanFailure],
        wasCancelled: Bool
    ) {
        self.scannedItemCount = scannedItemCount
        self.foundDSStoreCount = foundDSStoreCount
        self.removedDSStoreCount = removedDSStoreCount
        self.failureCount = failureCount
        self.failures = failures
        self.wasCancelled = wasCancelled
    }
}

public actor FullDiskScanner {
    private static let failureSampleLimit = 20

    public init() {}

    public func scanAndClean(
        rootURL: URL = URL(fileURLWithPath: "/", isDirectory: true)
    ) async -> FullDiskCleanupReport {
        var scannedItemCount = 0
        var foundDSStoreCount = 0
        var removedDSStoreCount = 0
        var failureCount = 0
        var failures: [FullDiskScanFailure] = []

        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isSymbolicLinkKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: rootURL.standardizedFileURL,
            includingPropertiesForKeys: resourceKeys,
            options: [],
            errorHandler: { url, error in
                failureCount += 1

                if failures.count < Self.failureSampleLimit {
                    failures.append(
                        FullDiskScanFailure(
                            fileURL: url,
                            message: error.localizedDescription
                        )
                    )
                }

                return true
            }
        ) else {
            return FullDiskCleanupReport(
                scannedItemCount: 0,
                foundDSStoreCount: 0,
                removedDSStoreCount: 0,
                failureCount: 1,
                failures: [
                    FullDiskScanFailure(
                        fileURL: rootURL,
                        message: "无法枚举扫描根目录"
                    )
                ],
                wasCancelled: false
            )
        }

        while let fileURL = enumerator.nextObject() as? URL {
            if Task.isCancelled {
                return FullDiskCleanupReport(
                    scannedItemCount: scannedItemCount,
                    foundDSStoreCount: foundDSStoreCount,
                    removedDSStoreCount: removedDSStoreCount,
                    failureCount: failureCount,
                    failures: failures,
                    wasCancelled: true
                )
            }

            scannedItemCount += 1

            guard fileURL.lastPathComponent == ".DS_Store" else {
                if Self.isSymbolicLink(fileURL, resourceKeys: resourceKeys) {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard !Self.isSymbolicLink(fileURL, resourceKeys: resourceKeys),
                  !Self.isDirectory(fileURL, resourceKeys: resourceKeys) else {
                continue
            }

            foundDSStoreCount += 1

            do {
                try FileManager.default.removeItem(at: fileURL)
                removedDSStoreCount += 1
            } catch CocoaError.fileNoSuchFile {
                continue
            } catch {
                failureCount += 1

                if failures.count < Self.failureSampleLimit {
                    failures.append(
                        FullDiskScanFailure(
                            fileURL: fileURL,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        }

        return FullDiskCleanupReport(
            scannedItemCount: scannedItemCount,
            foundDSStoreCount: foundDSStoreCount,
            removedDSStoreCount: removedDSStoreCount,
            failureCount: failureCount,
            failures: failures,
            wasCancelled: false
        )
    }

    private static func isSymbolicLink(
        _ fileURL: URL,
        resourceKeys: [URLResourceKey]
    ) -> Bool {
        (try? fileURL.resourceValues(forKeys: Set(resourceKeys)).isSymbolicLink) == true
    }

    private static func isDirectory(
        _ fileURL: URL,
        resourceKeys: [URLResourceKey]
    ) -> Bool {
        (try? fileURL.resourceValues(forKeys: Set(resourceKeys)).isDirectory) == true
    }
}
