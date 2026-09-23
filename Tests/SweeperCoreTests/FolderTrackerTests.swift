import Foundation
import SweeperCore
import XCTest

final class FolderTrackerTests: XCTestCase {
    func testTracksOpenFolderThenRetainsItDuringGracePeriod() {
        let folderURL = URL(fileURLWithPath: "/tmp/example", isDirectory: true)
        let initialDate = Date(timeIntervalSince1970: 1_000)
        var tracker = FolderTracker()

        let openFolders = tracker.update(
            openFolderURLs: [folderURL],
            at: initialDate,
            gracePeriod: 60
        )

        XCTAssertEqual(openFolders, [TrackedFolder(url: folderURL, state: .open)])

        let retainedFolders = tracker.update(
            openFolderURLs: [],
            at: initialDate.addingTimeInterval(5),
            gracePeriod: 60
        )

        XCTAssertEqual(
            retainedFolders,
            [
                TrackedFolder(
                    url: folderURL,
                    state: .gracePeriod(expiresAt: initialDate.addingTimeInterval(65))
                )
            ]
        )
    }

    func testRemovesFolderWhenGracePeriodExpires() {
        let folderURL = URL(fileURLWithPath: "/tmp/example", isDirectory: true)
        let initialDate = Date(timeIntervalSince1970: 1_000)
        var tracker = FolderTracker()

        tracker.update(
            openFolderURLs: [folderURL],
            at: initialDate,
            gracePeriod: 30
        )
        tracker.update(
            openFolderURLs: [],
            at: initialDate.addingTimeInterval(5),
            gracePeriod: 30
        )

        let trackedFolders = tracker.update(
            openFolderURLs: [],
            at: initialDate.addingTimeInterval(35),
            gracePeriod: 30
        )

        XCTAssertTrue(trackedFolders.isEmpty)
    }

    func testReopeningFolderCancelsGracePeriod() {
        let folderURL = URL(fileURLWithPath: "/tmp/example", isDirectory: true)
        let initialDate = Date(timeIntervalSince1970: 1_000)
        var tracker = FolderTracker()

        tracker.update(
            openFolderURLs: [folderURL],
            at: initialDate,
            gracePeriod: 60
        )
        tracker.update(
            openFolderURLs: [],
            at: initialDate.addingTimeInterval(5),
            gracePeriod: 60
        )

        let trackedFolders = tracker.update(
            openFolderURLs: [folderURL],
            at: initialDate.addingTimeInterval(10),
            gracePeriod: 60
        )

        XCTAssertEqual(trackedFolders, [TrackedFolder(url: folderURL, state: .open)])
    }
}

final class DSStoreCleanerTests: XCTestCase {
    private var temporaryDirectoryURL: URL!

    override func setUpWithError() throws {
        temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        temporaryDirectoryURL = nil
    }

    func testRemovesDSStoreFromTrackedFolderRootOnly() throws {
        let nestedDirectoryURL = temporaryDirectoryURL
            .appendingPathComponent("nested", isDirectory: true)
        try FileManager.default.createDirectory(
            at: nestedDirectoryURL,
            withIntermediateDirectories: true
        )

        let rootDSStoreURL = temporaryDirectoryURL
            .appendingPathComponent(".DS_Store", isDirectory: false)
        let nestedDSStoreURL = nestedDirectoryURL
            .appendingPathComponent(".DS_Store", isDirectory: false)
        try Data("root".utf8).write(to: rootDSStoreURL)
        try Data("nested".utf8).write(to: nestedDSStoreURL)

        let report = DSStoreCleaner().clean(folderURLs: [temporaryDirectoryURL])

        XCTAssertEqual(report.removedFileURLs, [rootDSStoreURL])
        XCTAssertTrue(report.failures.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: rootDSStoreURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedDSStoreURL.path))
    }

    func testMissingDSStoreIsNotReportedAsFailure() {
        let report = DSStoreCleaner().clean(folderURLs: [temporaryDirectoryURL])

        XCTAssertTrue(report.removedFileURLs.isEmpty)
        XCTAssertTrue(report.failures.isEmpty)
    }
}
