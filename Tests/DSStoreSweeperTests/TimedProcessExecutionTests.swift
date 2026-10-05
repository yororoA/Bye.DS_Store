import Foundation
import XCTest
@testable import DSStoreSweeper

final class TimedProcessExecutionTests: XCTestCase {
    func testCapturesOutputAndTerminationStatus() async throws {
        let execution = TimedProcessExecution(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                "printf 'standard output'; printf 'standard error' >&2; exit 7"
            ]
        )

        let result = try await execution.run(timeout: 2)

        XCTAssertEqual(result.terminationStatus, 7)
        XCTAssertEqual(
            String(data: result.standardOutput, encoding: .utf8),
            "standard output"
        )
        XCTAssertEqual(
            String(data: result.standardError, encoding: .utf8),
            "standard error"
        )
    }

    func testTerminatesProcessWhenTimeoutExpires() async {
        let execution = TimedProcessExecution(
            executableURL: URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["5"]
        )
        let startDate = Date()

        do {
            _ = try await execution.run(timeout: 0.1)
            XCTFail("Expected the process execution to time out")
        } catch ProcessExecutionError.timedOut {
            XCTAssertLessThan(Date().timeIntervalSince(startDate), 2)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTerminatesProcessWhenTaskIsCancelled() async {
        let execution = TimedProcessExecution(
            executableURL: URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["5"]
        )
        let task = Task {
            try await execution.run(timeout: 10)
        }

        try? await Task.sleep(for: .milliseconds(100))
        let startDate = Date()
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            XCTAssertLessThan(Date().timeIntervalSince(startDate), 2)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
