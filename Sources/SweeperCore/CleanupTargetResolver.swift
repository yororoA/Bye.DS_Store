import Foundation

public enum CleanupScope: String, CaseIterable, Hashable, Sendable {
    case monitoredAndParent = "monitored-and-parent"
    case monitoredOnly = "monitored-only"

    public var title: String {
        switch self {
        case .monitoredAndParent:
            return "被监控文件夹及其父文件夹"
        case .monitoredOnly:
            return "仅被监控文件夹"
        }
    }
}

public struct CleanupTargetResolver: Sendable {
    public init() {}

    public func resolve(folderURLs: [URL], scope: CleanupScope) -> [URL] {
        var uniqueURLs: [String: URL] = [:]

        for folderURL in folderURLs {
            let normalizedURL = folderURL.standardizedFileURL
            uniqueURLs[normalizedURL.path] = normalizedURL

            if scope == .monitoredAndParent {
                let parentURL = normalizedURL.deletingLastPathComponent().standardizedFileURL
                uniqueURLs[parentURL.path] = parentURL
            }
        }

        return uniqueURLs.values.sorted {
            $0.path.localizedStandardCompare($1.path) == .orderedAscending
        }
    }
}
