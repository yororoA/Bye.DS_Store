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
    case installing(AppUpdateRelease)
    case failed
}

struct PreparedAppUpdate: Sendable {
    let stagedAppURL: URL
    let destinationAppURL: URL
    let mountedVolumeURL: URL?
}

struct AppUpdateClient: Sendable {
    static let applicationBundleIdentifier = "com.local.ds-store-sweeper"

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

    func prepareInstallation(
        for diskImageURL: URL,
        currentBundleURL: URL,
        expectedBundleIdentifier: String
    ) async throws -> PreparedAppUpdate {
        try await Task.detached(priority: .userInitiated) {
            try self.prepareInstallationSynchronously(
                for: diskImageURL,
                currentBundleURL: currentBundleURL,
                expectedBundleIdentifier: expectedBundleIdentifier
            )
        }.value
    }

    func launchInstallation(
        _ installation: PreparedAppUpdate,
        waitingFor processIDs: [Int32]
    ) throws {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "Bye.DS_Store-update-\(UUID().uuidString).sh"
            )
        guard let scriptData = Self.installationScript.data(using: .utf8) else {
            throw UpdateClientError.processFailed(
                "The update installer could not be prepared."
            )
        }
        try scriptData.write(to: scriptURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: scriptURL.path
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            scriptURL.path,
            installation.stagedAppURL.path,
            installation.destinationAppURL.path,
            processIDs.map(String.init).joined(separator: ","),
            installation.mountedVolumeURL?.path ?? ""
        ]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            try? FileManager.default.removeItem(at: scriptURL)
            try? FileManager.default.removeItem(
                at: installation.stagedAppURL
            )
            throw error
        }
    }
}

private extension AppUpdateClient {
    enum UpdateClientError: LocalizedError {
        case invalidDiskImage
        case applicationNotFound
        case bundleIdentifierMismatch
        case noWritableInstallationLocation
        case processFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidDiskImage:
                return "The downloaded disk image could not be mounted."
            case .applicationNotFound:
                return "The downloaded application was not found."
            case .bundleIdentifierMismatch:
                return "The downloaded application is not Bye.DS_Store."
            case .noWritableInstallationLocation:
                return "No writable installation location is available."
            case .processFailed(let message):
                return message
            }
        }
    }

    static let installationScript = """
    #!/bin/bash
    set -euo pipefail

    staged_app="$1"
    destination_app="$2"
    process_ids="$3"
    mounted_volume="$4"
    script_path="$0"

    cleanup() {
        rm -rf -- "$staged_app"
        rm -f -- "$script_path"
    }

    trap cleanup EXIT

    for _ in $(/usr/bin/seq 1 120); do
        running=0
        IFS=',' read -r -a pids <<< "$process_ids"
        for pid in "${pids[@]}"; do
            if [[ -n "$pid" ]] && /bin/kill -0 "$pid" 2>/dev/null; then
                running=1
                break
            fi
        done

        if [[ "$running" -eq 0 ]]; then
            break
        fi
        /bin/sleep 0.25
    done

    IFS=',' read -r -a pids <<< "$process_ids"
    for pid in "${pids[@]}"; do
        if [[ -n "$pid" ]] && /bin/kill -0 "$pid" 2>/dev/null; then
            exit 1
        fi
    done

    destination_parent="$(dirname "$destination_app")"
    mkdir -p "$destination_parent"

    installing_app="${destination_app}.installing.$$"
    backup_app="${destination_app}.previous.$$"
    rm -rf -- "$installing_app" "$backup_app"

    mv -- "$staged_app" "$installing_app"

    if [[ -e "$destination_app" ]]; then
        mv -- "$destination_app" "$backup_app"
    fi

    if ! mv -- "$installing_app" "$destination_app"; then
        if [[ -e "$backup_app" ]]; then
            mv -- "$backup_app" "$destination_app"
        fi
        exit 1
    fi

    rm -rf -- "$backup_app"

    if [[ -n "$mounted_volume" ]]; then
        /usr/bin/hdiutil detach "$mounted_volume" >/dev/null 2>&1 \
            || /usr/bin/hdiutil detach -force "$mounted_volume" >/dev/null 2>&1 \
            || true
    fi

    /usr/bin/open "$destination_app"
    """

    func prepareInstallationSynchronously(
        for diskImageURL: URL,
        currentBundleURL: URL,
        expectedBundleIdentifier: String
    ) throws -> PreparedAppUpdate {
        let fileManager = FileManager.default
        let currentURL = currentBundleURL
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let destinationURL = try installationDestination(
            for: currentURL,
            fileManager: fileManager
        )
        let mountedVolumeURL = mountedVolumeToDetach(for: currentURL)
        let stagingURL = destinationURL
            .deletingLastPathComponent()
            .appendingPathComponent(
                ".Bye.DS_Store-\(UUID().uuidString).app"
            )

        let mountPoint = try attachDiskImage(at: diskImageURL)
        defer {
            detachDiskImage(at: mountPoint)
        }

        do {
            let sourceAppURL = try findApplication(in: mountPoint)
            guard applicationBundleIdentifier(at: sourceAppURL)
                == expectedBundleIdentifier else {
                throw UpdateClientError.bundleIdentifierMismatch
            }

            _ = try runProcess(
                "/usr/bin/ditto",
                arguments: [
                    "--rsrc",
                    "--extattr",
                    "--acl",
                    sourceAppURL.path,
                    stagingURL.path
                ]
            )

            guard fileManager.fileExists(atPath: stagingURL.path) else {
                throw UpdateClientError.applicationNotFound
            }

            return PreparedAppUpdate(
                stagedAppURL: stagingURL,
                destinationAppURL: destinationURL,
                mountedVolumeURL: mountedVolumeURL
            )
        } catch {
            try? fileManager.removeItem(at: stagingURL)
            throw error
        }
    }

    func installationDestination(
        for currentBundleURL: URL,
        fileManager: FileManager
    ) throws -> URL {
        let currentURL = currentBundleURL
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let values = try? currentURL.resourceValues(forKeys: [
            .volumeIsReadOnlyKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey
        ])
        let isMountedReadOnlyVolume = values?.volumeIsReadOnly == true
        let isRemovableVolume = values?.volumeIsRemovable == true
            || values?.volumeIsEjectable == true

        if currentURL.pathExtension == "app",
           !isMountedReadOnlyVolume,
           !isRemovableVolume,
           canInstall(at: currentURL, fileManager: fileManager) {
            return currentURL
        }

        let systemApplicationsURL = URL(fileURLWithPath: "/Applications")
            .appendingPathComponent("Bye.DS_Store.app")
        if canInstall(at: systemApplicationsURL, fileManager: fileManager) {
            return systemApplicationsURL
        }

        let userApplicationsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
        do {
            try fileManager.createDirectory(
                at: userApplicationsURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw UpdateClientError.noWritableInstallationLocation
        }

        let userAppURL = userApplicationsURL
            .appendingPathComponent("Bye.DS_Store.app")
        guard canInstall(at: userAppURL, fileManager: fileManager) else {
            throw UpdateClientError.noWritableInstallationLocation
        }
        return userAppURL
    }

    func canInstall(at destinationURL: URL, fileManager: FileManager) -> Bool {
        let parentURL = destinationURL.deletingLastPathComponent()
        guard fileManager.fileExists(atPath: parentURL.path),
              fileManager.isWritableFile(atPath: parentURL.path) else {
            return false
        }

        return !fileManager.fileExists(atPath: destinationURL.path)
            || fileManager.isWritableFile(atPath: destinationURL.path)
    }

    func mountedVolumeToDetach(for currentBundleURL: URL) -> URL? {
        let fileManager = FileManager.default
        let currentPath = currentBundleURL.standardizedFileURL.path
        let resourceKeys: Set<URLResourceKey> = [
            .volumeIsReadOnlyKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey
        ]
        let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(resourceKeys),
            options: []
        ) ?? []

        return mountedVolumes
            .filter { volumeURL in
                let volumePath = volumeURL.standardizedFileURL.path
                return currentPath == volumePath
                    || currentPath.hasPrefix(volumePath + "/")
            }
            .sorted { $0.path.count > $1.path.count }
            .first { volumeURL in
                guard let values = try? volumeURL.resourceValues(
                    forKeys: resourceKeys
                ) else {
                    return false
                }
                return values.volumeIsReadOnly == true
                    && (values.volumeIsRemovable == true
                        || values.volumeIsEjectable == true)
            }
    }

    func attachDiskImage(at diskImageURL: URL) throws -> URL {
        let output = try runProcess(
            "/usr/bin/hdiutil",
            arguments: [
                "attach",
                "-nobrowse",
                "-readonly",
                "-plist",
                diskImageURL.path
            ]
        )
        guard let propertyList = try PropertyListSerialization.propertyList(
            from: output,
            options: [],
            format: nil
        ) as? [String: Any],
        let entities = propertyList["system-entities"] as? [[String: Any]],
        let mountPath = entities.compactMap({
            $0["mount-point"] as? String
        }).first else {
            throw UpdateClientError.invalidDiskImage
        }

        return URL(fileURLWithPath: mountPath, isDirectory: true)
    }

    func detachDiskImage(at mountPoint: URL) {
        do {
            _ = try runProcess(
                "/usr/bin/hdiutil",
                arguments: ["detach", mountPoint.path]
            )
        } catch {
            _ = try? runProcess(
                "/usr/bin/hdiutil",
                arguments: ["detach", "-force", mountPoint.path]
            )
        }
    }

    func findApplication(in mountPoint: URL) throws -> URL {
        let fileManager = FileManager.default
        let directChildren = try fileManager.contentsOfDirectory(
            at: mountPoint,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        if let directApplication = directChildren.first(where: {
            $0.pathExtension.lowercased() == "app"
        }) {
            return directApplication
        }

        guard let enumerator = fileManager.enumerator(
            at: mountPoint,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw UpdateClientError.applicationNotFound
        }

        for case let url as URL in enumerator
            where url.pathExtension.lowercased() == "app" {
            return url
        }
        throw UpdateClientError.applicationNotFound
    }

    func applicationBundleIdentifier(at appURL: URL) -> String? {
        let infoURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoURL),
              let propertyList = try? PropertyListSerialization.propertyList(
                  from: data,
                  options: [],
                  format: nil
              ) as? [String: Any] else {
            return nil
        }
        return propertyList["CFBundleIdentifier"] as? String
    }

    func runProcess(_ executablePath: String, arguments: [String]) throws -> Data {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw UpdateClientError.processFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let message = String(
                data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            )?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw UpdateClientError.processFailed(
                message?.isEmpty == false
                    ? message!
                    : "\(executablePath) failed"
            )
        }
        return output
    }
}
