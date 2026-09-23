import Foundation

public struct CleanupFailure: Equatable, Sendable {
    public let folderURL: URL
    public let message: String

    public init(folderURL: URL, message: String) {
        self.folderURL = folderURL
        self.message = message
    }
}

public struct CleanupReport: Equatable, Sendable {
    public let removedFileURLs: [URL]
    public let failures: [CleanupFailure]

    public init(removedFileURLs: [URL], failures: [CleanupFailure]) {
        self.removedFileURLs = removedFileURLs
        self.failures = failures
    }
}

public struct DSStoreCleaner: Sendable {
    public init() {}

    public func clean(folderURLs: [URL]) -> CleanupReport {
        var uniqueFolders: [String: URL] = [:]

        for url in folderURLs {
            let normalizedURL = url.standardizedFileURL
            uniqueFolders[normalizedURL.path] = normalizedURL
        }

        var removedFileURLs: [URL] = []
        var failures: [CleanupFailure] = []

        for folderURL in uniqueFolders.values {
            let dsStoreURL = folderURL.appendingPathComponent(".DS_Store", isDirectory: false)

            do {
                try FileManager.default.removeItem(at: dsStoreURL)
                removedFileURLs.append(dsStoreURL)
            } catch CocoaError.fileNoSuchFile {
                continue
            } catch {
                failures.append(
                    CleanupFailure(
                        folderURL: folderURL,
                        message: error.localizedDescription
                    )
                )
            }
        }

        return CleanupReport(
            removedFileURLs: removedFileURLs.sorted { $0.path < $1.path },
            failures: failures.sorted { $0.folderURL.path < $1.folderURL.path }
        )
    }
}
