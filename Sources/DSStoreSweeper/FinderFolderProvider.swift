import Darwin
import Foundation

enum FinderFolderProviderError: LocalizedError, Sendable {
    case automationDenied(String)
    case queryTimedOut
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .automationDenied(let message), .scriptFailed(let message):
            return message
        case .queryTimedOut:
            return "Finder query timed out. Check Finder and disconnected network drives."
        }
    }
}

actor FinderFolderProvider {
    private static let processTimeout: TimeInterval = 7
    private static let outputSeparator = "\u{001E}"
    private static let scriptSource = """
        with timeout of 5 seconds
            tell application "Finder"
                set openFolders to {}
                repeat with windowIndex from 1 to (count of Finder windows)
                    try
                        set end of openFolders to POSIX path of (target of Finder window windowIndex as alias)
                    end try
                end repeat
            end tell
        end timeout

        set previousDelimiters to AppleScript's text item delimiters
        set AppleScript's text item delimiters to ASCII character 30
        set outputText to openFolders as text
        set AppleScript's text item delimiters to previousDelimiters
        return outputText
        """

    func openFolderURLs() async throws -> Set<URL> {
        let execution = TimedProcessExecution(
            executableURL: URL(fileURLWithPath: "/usr/bin/osascript"),
            arguments: ["-e", Self.scriptSource]
        )

        let result: ProcessExecutionResult
        do {
            result = try await execution.run(timeout: Self.processTimeout)
        } catch ProcessExecutionError.timedOut {
            throw FinderFolderProviderError.queryTimedOut
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw FinderFolderProviderError.scriptFailed(
                error.localizedDescription
            )
        }

        guard result.terminationStatus == 0 else {
            let message = String(
                data: result.standardError,
                encoding: .utf8
            )?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? "Finder 查询失败"

            if message.contains("-1743") {
                throw FinderFolderProviderError.automationDenied(message)
            }

            if message.contains("-1712") {
                throw FinderFolderProviderError.queryTimedOut
            }

            throw FinderFolderProviderError.scriptFailed(message)
        }

        guard var output = String(
            data: result.standardOutput,
            encoding: .utf8
        ) else {
            throw FinderFolderProviderError.scriptFailed(
                "无法读取 Finder 查询结果"
            )
        }

        output = output.trimmingCharacters(in: .newlines)
        guard !output.isEmpty else {
            return []
        }

        return Set(
            output
                .components(separatedBy: Self.outputSeparator)
                .filter { !$0.isEmpty }
                .map {
                    URL(
                        fileURLWithPath: $0,
                        isDirectory: true
                    ).standardizedFileURL
                }
        )
    }
}

struct ProcessExecutionResult: Sendable {
    let terminationStatus: Int32
    let standardOutput: Data
    let standardError: Data
}

enum ProcessExecutionError: Error {
    case timedOut
}

final class TimedProcessExecution: @unchecked Sendable {
    private let process: Process
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private let stateLock = NSLock()
    private var continuation: CheckedContinuation<
        ProcessExecutionResult,
        Error
    >?
    private var completion: Result<ProcessExecutionResult, Error>?
    private var timeoutWorkItem: DispatchWorkItem?

    init(executableURL: URL, arguments: [String]) {
        process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = outputPipe
        process.standardError = errorPipe
    }

    func run(timeout: TimeInterval) async throws -> ProcessExecutionResult {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                start(continuation: continuation, timeout: timeout)
            }
        } onCancel: {
            finish(with: .failure(CancellationError()))
            terminateProcess()
        }
    }

    private func start(
        continuation: CheckedContinuation<ProcessExecutionResult, Error>,
        timeout: TimeInterval
    ) {
        stateLock.lock()
        if let completion {
            stateLock.unlock()
            continuation.resume(with: completion)
            return
        }
        self.continuation = continuation
        stateLock.unlock()

        process.terminationHandler = { [weak self] process in
            self?.processDidTerminate(process)
        }

        do {
            try process.run()
        } catch {
            finish(with: .failure(error))
            return
        }

        if hasCompleted {
            terminateProcess()
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            let didTimeOut = self.finish(
                with: .failure(ProcessExecutionError.timedOut)
            )
            if didTimeOut {
                self.terminateProcess()
            }
        }

        stateLock.lock()
        if completion == nil {
            timeoutWorkItem = workItem
            stateLock.unlock()
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + timeout,
                execute: workItem
            )
        } else {
            stateLock.unlock()
        }
    }

    private var hasCompleted: Bool {
        stateLock.lock()
        defer {
            stateLock.unlock()
        }
        return completion != nil
    }

    private func processDidTerminate(_ process: Process) {
        let result = ProcessExecutionResult(
            terminationStatus: process.terminationStatus,
            standardOutput: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            standardError: errorPipe.fileHandleForReading.readDataToEndOfFile()
        )
        finish(with: .success(result))
    }

    @discardableResult
    private func finish(
        with result: Result<ProcessExecutionResult, Error>
    ) -> Bool {
        let continuation: CheckedContinuation<ProcessExecutionResult, Error>?
        let timeoutWorkItem: DispatchWorkItem?

        stateLock.lock()
        guard completion == nil else {
            stateLock.unlock()
            return false
        }
        completion = result
        continuation = self.continuation
        self.continuation = nil
        timeoutWorkItem = self.timeoutWorkItem
        self.timeoutWorkItem = nil
        stateLock.unlock()

        timeoutWorkItem?.cancel()
        continuation?.resume(with: result)
        return true
    }

    private func terminateProcess() {
        guard process.isRunning else {
            return
        }

        Darwin.kill(process.processIdentifier, SIGKILL)
    }
}
