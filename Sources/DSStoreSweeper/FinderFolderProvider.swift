import AppKit
import Foundation

enum FinderFolderProviderError: LocalizedError, Sendable {
    case automationDenied(String)
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .automationDenied(let message), .scriptFailed(let message):
            return message
        }
    }
}

actor FinderFolderProvider {
    private static let scriptSource = """
        tell application "Finder"
            set openFolders to {}
            repeat with windowIndex from 1 to (count of Finder windows)
                try
                    set end of openFolders to POSIX path of (target of Finder window windowIndex as alias)
                end try
            end repeat
            return openFolders
        end tell
        """

    func openFolderURLs() throws -> Set<URL> {
        guard let script = NSAppleScript(source: Self.scriptSource) else {
            throw FinderFolderProviderError.scriptFailed("无法创建 Finder 查询脚本")
        }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let errorNumber = errorInfo["NSAppleScriptErrorNumber"] as? Int
            let message = (errorInfo["NSAppleScriptErrorMessage"] as? String)
                ?? "Finder 查询失败"

            if errorNumber == -1743 {
                throw FinderFolderProviderError.automationDenied(message)
            }

            throw FinderFolderProviderError.scriptFailed(message)
        }

        var folderURLs = Set<URL>()

        guard result.numberOfItems > 0 else {
            return folderURLs
        }

        for index in 1...result.numberOfItems {
            guard let path = result.atIndex(index)?.stringValue, !path.isEmpty else {
                continue
            }

            folderURLs.insert(URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL)
        }

        return folderURLs
    }
}
