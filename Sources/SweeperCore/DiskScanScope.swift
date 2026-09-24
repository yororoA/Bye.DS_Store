import Foundation

public enum DiskScanScope: String, CaseIterable, Hashable, Sendable {
    case startupDisk = "startup-disk"
    case externalDisks = "external-disks"
    case networkDisks = "network-disks"
    case allMountedVolumes = "all-mounted-volumes"

    public var title: String {
        switch self {
        case .startupDisk:
            return "仅启动磁盘"
        case .externalDisks:
            return "启动磁盘和外接磁盘"
        case .networkDisks:
            return "启动磁盘和网络磁盘"
        case .allMountedVolumes:
            return "所有已挂载磁盘"
        }
    }
}

public struct MountedVolumeResolver: Sendable {
    public init() {}

    public func excludedVolumeURLs(for scope: DiskScanScope) -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [
            .volumeIsEjectableKey,
            .volumeIsInternalKey,
            .volumeIsLocalKey,
            .volumeIsRemovableKey,
            .volumeIsRootFileSystemKey
        ]
        let rootURL = URL(fileURLWithPath: "/", isDirectory: true)
            .standardizedFileURL

        let mountedVolumes = FileManager.default
            .mountedVolumeURLs(
                includingResourceValuesForKeys: Array(resourceKeys),
                options: []
            )?
            .compactMap { url -> (URL, URLResourceValues)? in
                guard let values = try? url.resourceValues(forKeys: resourceKeys) else {
                    return nil
                }
                return (url.standardizedFileURL, values)
            } ?? []

        return mountedVolumes.compactMap { url, values in
            guard url != rootURL else {
                return nil
            }

            let shouldInclude: Bool

            switch scope {
            case .startupDisk:
                shouldInclude = false
            case .externalDisks:
                shouldInclude = isExternal(values)
            case .networkDisks:
                shouldInclude = values.volumeIsLocal != true
            case .allMountedVolumes:
                shouldInclude = true
            }

            return shouldInclude ? nil : url
        }
    }

    private func isExternal(_ values: URLResourceValues) -> Bool {
        values.volumeIsRemovable == true
            || values.volumeIsEjectable == true
            || (
                values.volumeIsInternal == false
                    && values.volumeIsLocal == true
            )
    }
}
