import Combine
import Foundation
import SweeperCore

@MainActor
final class AppSettings: ObservableObject {
    static let pollingIntervals: [TimeInterval] = [2, 5, 10, 30, 60]
    static let gracePeriods: [TimeInterval] = [15, 30, 60, 120, 300]

    private enum Key {
        static let isMonitoringEnabled = "isMonitoringEnabled"
        static let pollingInterval = "pollingInterval"
        static let gracePeriod = "gracePeriod"
        static let cleanupScope = "cleanupScope"
    }

    @Published var isMonitoringEnabled: Bool {
        didSet {
            defaults.set(isMonitoringEnabled, forKey: Key.isMonitoringEnabled)
        }
    }

    @Published var pollingInterval: TimeInterval {
        didSet {
            defaults.set(pollingInterval, forKey: Key.pollingInterval)
        }
    }

    @Published var gracePeriod: TimeInterval {
        didSet {
            defaults.set(gracePeriod, forKey: Key.gracePeriod)
        }
    }

    @Published var cleanupScope: CleanupScope {
        didSet {
            defaults.set(cleanupScope.rawValue, forKey: Key.cleanupScope)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.isMonitoringEnabled) == nil {
            isMonitoringEnabled = true
        } else {
            isMonitoringEnabled = defaults.bool(forKey: Key.isMonitoringEnabled)
        }

        let storedPollingInterval = defaults.double(forKey: Key.pollingInterval)
        pollingInterval = Self.pollingIntervals.contains(storedPollingInterval)
            ? storedPollingInterval
            : 5

        let storedGracePeriod = defaults.double(forKey: Key.gracePeriod)
        gracePeriod = Self.gracePeriods.contains(storedGracePeriod)
            ? storedGracePeriod
            : 60

        cleanupScope = CleanupScope(
            rawValue: defaults.string(forKey: Key.cleanupScope) ?? ""
        ) ?? .monitoredAndParent
    }
}
