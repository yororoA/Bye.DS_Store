import Foundation

public struct AdaptivePollingPolicy: Sendable {
    public let maximumIdleInterval: TimeInterval

    public init(maximumIdleInterval: TimeInterval = 60) {
        self.maximumIdleInterval = maximumIdleInterval
    }

    public func interval(
        baseInterval: TimeInterval,
        consecutiveIdlePolls: Int
    ) -> TimeInterval {
        guard consecutiveIdlePolls > 0 else {
            return baseInterval
        }

        let multiplier = pow(2, Double(min(consecutiveIdlePolls, 5)))
        return min(baseInterval * multiplier, maximumIdleInterval)
    }
}
