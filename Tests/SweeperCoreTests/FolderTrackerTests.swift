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

final class CleanupTargetResolverTests: XCTestCase {
    func testDefaultScopeIncludesDirectParentFolder() {
        let folderURL = URL(fileURLWithPath: "/tmp/project/src", isDirectory: true)
        let parentURL = URL(fileURLWithPath: "/tmp/project", isDirectory: true)

        let targets = CleanupTargetResolver().resolve(
            folderURLs: [folderURL],
            scope: .monitoredAndParent
        )

        XCTAssertEqual(Set(targets), Set([folderURL, parentURL]))
    }

    func testMonitoredOnlyScopeDoesNotIncludeParentFolder() {
        let folderURL = URL(fileURLWithPath: "/tmp/project/src", isDirectory: true)
        let parentURL = URL(fileURLWithPath: "/tmp/project", isDirectory: true)

        let targets = CleanupTargetResolver().resolve(
            folderURLs: [folderURL],
            scope: .monitoredOnly
        )

        XCTAssertEqual(targets, [folderURL])
        XCTAssertFalse(targets.contains(parentURL))
    }

    func testDuplicateFoldersAndParentsAreDeduplicated() {
        let firstFolderURL = URL(fileURLWithPath: "/tmp/project/src", isDirectory: true)
        let secondFolderURL = URL(fileURLWithPath: "/tmp/project/tests", isDirectory: true)
        let parentURL = URL(fileURLWithPath: "/tmp/project", isDirectory: true)

        let targets = CleanupTargetResolver().resolve(
            folderURLs: [firstFolderURL, secondFolderURL, firstFolderURL],
            scope: .monitoredAndParent
        )

        XCTAssertEqual(
            Set(targets),
            Set([firstFolderURL, secondFolderURL, parentURL])
        )
    }
}

final class FolderExclusionPatternTests: XCTestCase {
    func testMatchesFolderNameAnywhereInPath() {
        let pattern = FolderExclusionPattern("node_modules")

        XCTAssertNotNil(pattern)
        XCTAssertTrue(
            pattern?.matches(
                directoryURL: URL(fileURLWithPath: "/tmp/project/node_modules")
            ) == true
        )
        XCTAssertTrue(
            pattern?.matches(
                directoryURL: URL(fileURLWithPath: "/tmp/project/apps/node_modules")
            ) == true
        )
    }

    func testMatchesParentAndTargetFolderPath() {
        let pattern = FolderExclusionPattern("/lib/packages/")

        XCTAssertEqual(pattern?.value, "lib/packages")
        XCTAssertTrue(
            pattern?.matches(
                directoryURL: URL(fileURLWithPath: "/tmp/project/lib/packages")
            ) == true
        )
        XCTAssertFalse(
            pattern?.matches(
                directoryURL: URL(fileURLWithPath: "/tmp/project/library/packages")
            ) == true
        )
        XCTAssertFalse(
            pattern?.matches(
                directoryURL: URL(fileURLWithPath: "/tmp/project/lib/other")
            ) == true
        )
    }

    func testRejectsEmptyAndParentTraversalPatterns() {
        XCTAssertNil(FolderExclusionPattern(""))
        XCTAssertNil(FolderExclusionPattern("/"))
        XCTAssertNil(FolderExclusionPattern("../packages"))
        XCTAssertNil(FolderExclusionPattern("lib/../packages"))
    }
}

final class FullDiskScannerTests: XCTestCase {
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

    func testScansAndRemovesNestedDSStoreFiles() async throws {
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

        let report = await FullDiskScanner().scanAndClean(rootURL: temporaryDirectoryURL)

        XCTAssertEqual(report.foundDSStoreCount, 2)
        XCTAssertEqual(report.removedDSStoreCount, 2)
        XCTAssertEqual(report.failureCount, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: rootDSStoreURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: nestedDSStoreURL.path))
    }

    func testSkipsExcludedFolderAndItsDescendants() async throws {
        let excludedDirectoryURL = temporaryDirectoryURL
            .appendingPathComponent("node_modules", isDirectory: true)
        try FileManager.default.createDirectory(
            at: excludedDirectoryURL,
            withIntermediateDirectories: true
        )

        let excludedDSStoreURL = excludedDirectoryURL
            .appendingPathComponent(".DS_Store", isDirectory: false)
        let regularDSStoreURL = temporaryDirectoryURL
            .appendingPathComponent(".DS_Store", isDirectory: false)
        try Data("excluded".utf8).write(to: excludedDSStoreURL)
        try Data("regular".utf8).write(to: regularDSStoreURL)

        let pattern = try XCTUnwrap(FolderExclusionPattern("node_modules"))
        let report = await FullDiskScanner().scanAndClean(
            rootURL: temporaryDirectoryURL,
            excluding: [pattern]
        )

        XCTAssertEqual(report.foundDSStoreCount, 1)
        XCTAssertEqual(report.removedDSStoreCount, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: regularDSStoreURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: excludedDSStoreURL.path))
    }
}
