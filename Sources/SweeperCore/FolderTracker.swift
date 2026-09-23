import Foundation

public struct TrackedFolder: Identifiable, Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case open
        case gracePeriod(expiresAt: Date)
    }

    public let url: URL
    public let state: State

    public var id: URL { url }

    public init(url: URL, state: State) {
        self.url = url
        self.state = state
    }
}

public struct FolderTracker: Sendable {
    private struct Entry: Sendable {
        let url: URL
        var expiresAt: Date?
    }

    private var entriesByPath: [String: Entry] = [:]

    public init() {}

    @discardableResult
    public mutating func update(
        openFolderURLs: Set<URL>,
        at date: Date,
        gracePeriod: TimeInterval
    ) -> [TrackedFolder] {
        var normalizedOpenFolders: [String: URL] = [:]

        for url in openFolderURLs {
            let normalizedURL = Self.normalize(url)
            normalizedOpenFolders[normalizedURL.path] = normalizedURL
        }

        for (path, url) in normalizedOpenFolders {
            entriesByPath[path] = Entry(url: url, expiresAt: nil)
        }

        for path in Array(entriesByPath.keys) where normalizedOpenFolders[path] == nil {
            guard var entry = entriesByPath[path] else {
                continue
            }

            if let expiresAt = entry.expiresAt {
                if expiresAt <= date {
                    entriesByPath.removeValue(forKey: path)
                }
            } else {
                entry.expiresAt = date.addingTimeInterval(max(0, gracePeriod))
                entriesByPath[path] = entry
            }
        }

        return trackedFolders
    }

    public var trackedFolders: [TrackedFolder] {
        entriesByPath.values
            .map { entry in
                let state = entry.expiresAt.map(TrackedFolder.State.gracePeriod) ?? .open
                return TrackedFolder(url: entry.url, state: state)
            }
            .sorted(by: Self.sortFolders)
    }

    private static func normalize(_ url: URL) -> URL {
        url.standardizedFileURL
    }

    private static func sortFolders(_ lhs: TrackedFolder, _ rhs: TrackedFolder) -> Bool {
        switch (lhs.state, rhs.state) {
        case (.open, .gracePeriod):
            return true
        case (.gracePeriod, .open):
            return false
        case (.open, .open), (.gracePeriod, .gracePeriod):
            return lhs.url.path.localizedStandardCompare(rhs.url.path) == .orderedAscending
        }
    }
}
