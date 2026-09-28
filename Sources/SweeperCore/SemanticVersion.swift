import Foundation

public struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init?(_ value: String) {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .drop(while: { $0 == "v" || $0 == "V" })
        let components = normalized
            .split(separator: ".", omittingEmptySubsequences: false)

        guard (1...3).contains(components.count),
              components.allSatisfy({ $0.allSatisfy(\.isNumber) }),
              let major = Int(components[0]),
              let minor = components.count > 1 ? Int(components[1]) : 0,
              let patch = components.count > 2 ? Int(components[2]) : 0 else {
            return nil
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}
