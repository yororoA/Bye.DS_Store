import XCTest
@testable import SweeperCore

final class AdaptivePollingPolicyTests: XCTestCase {
    func testUsesConfiguredIntervalWhileMonitoringFolders() {
        let policy = AdaptivePollingPolicy()

        XCTAssertEqual(
            policy.interval(baseInterval: 5, consecutiveIdlePolls: 0),
            5
        )
    }

    func testBacksOffWhileIdleAndCapsTheInterval() {
        let policy = AdaptivePollingPolicy(maximumIdleInterval: 60)

        XCTAssertEqual(
            policy.interval(baseInterval: 5, consecutiveIdlePolls: 1),
            10
        )
        XCTAssertEqual(
            policy.interval(baseInterval: 5, consecutiveIdlePolls: 3),
            40
        )
        XCTAssertEqual(
            policy.interval(baseInterval: 5, consecutiveIdlePolls: 5),
            60
        )
        XCTAssertEqual(
            policy.interval(baseInterval: 5, consecutiveIdlePolls: 20),
            60
        )
    }
}
