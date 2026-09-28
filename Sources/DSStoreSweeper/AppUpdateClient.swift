import Foundation
import SweeperCore

struct AppUpdateRelease: Equatable, Sendable {
    let version: SemanticVersion
    let tagName: String
    let releaseURL: URL
    let downloadURL: URL
}

enum AppUpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case available(AppUpdateRelease)
    case downloading(AppUpdateRelease)
    case readyToInstall(AppUpdateRelease)
    case failed
}

struct AppUpdateClient: Sendable {
    private static let updateManifestURL = URL(
        string: "https://bye-dsstore.yororoice.top/release.json"
    )!

    private struct UpdateManifest: Decodable {
        let version: String
        let dmgURL: URL
        let releaseURL: URL

        enum CodingKeys: String, CodingKey {
            case version
            case dmgURL = "dmgUrl"
            case releaseURL = "releaseUrl"
        }
    }

    func latestRelease(
        newerThan currentVersion: SemanticVersion
    ) async throws -> AppUpdateRelease? {
        var request = URLRequest(url: Self.updateManifestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bye.DS_Store/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let manifest = try JSONDecoder().decode(UpdateManifest.self, from: data)
        guard let version = SemanticVersion(manifest.version),
              version > currentVersion else {
            return nil
        }

        return AppUpdateRelease(
            version: version,
            tagName: manifest.version,
            releaseURL: manifest.releaseURL,
            downloadURL: manifest.dmgURL
        )
    }

    func download(_ release: AppUpdateRelease) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(
            from: release.downloadURL
        )
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Bye.DS_Store-\(release.version).dmg")
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

}
