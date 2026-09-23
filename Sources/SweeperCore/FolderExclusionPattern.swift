import Foundation

public struct FolderExclusionPattern: Hashable, Sendable {
    public let value: String

    private let components: [String]

    public init?(_ input: String) {
        let normalizedComponents = input
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !normalizedComponents.isEmpty,
              normalizedComponents.allSatisfy({ $0 != "." && $0 != ".." }) else {
            return nil
        }

        value = normalizedComponents.joined(separator: "/")
        components = normalizedComponents
    }

    public func matches(directoryURL: URL) -> Bool {
        let directoryComponents = directoryURL.standardizedFileURL.pathComponents
            .filter { $0 != "/" }

        guard directoryComponents.count >= components.count else {
            return false
        }

        let suffix = directoryComponents.suffix(components.count)
        return zip(suffix, components).allSatisfy { directoryComponent, patternComponent in
            directoryComponent.caseInsensitiveCompare(patternComponent) == .orderedSame
        }
    }
}
