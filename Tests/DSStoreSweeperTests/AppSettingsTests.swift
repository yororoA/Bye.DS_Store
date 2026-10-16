import Foundation
import XCTest
@testable import DSStoreSweeper

@MainActor
final class AppSettingsTests: XCTestCase {
    func testAutomaticInstallationIsDisabledByDefault() {
        let defaults = makeDefaults()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let settings = AppSettings(defaults: defaults)

        XCTAssertFalse(settings.automaticallyInstallUpdates)
    }

    func testAutomaticInstallationPreferencePersists() {
        let defaults = makeDefaults()
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let settings = AppSettings(defaults: defaults)
        settings.automaticallyInstallUpdates = true

        let reloadedSettings = AppSettings(defaults: defaults)
        XCTAssertTrue(reloadedSettings.automaticallyInstallUpdates)
    }

    private var suiteName: String {
        "AppSettingsTests.\(name)"
    }

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
