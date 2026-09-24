import AppKit
import Foundation

@MainActor
final class GlobalShortcutMonitor {
    private enum KeyCode {
        static let b: UInt16 = 11
        static let space: UInt16 = 49
    }

    private let sequenceTimeout: TimeInterval = 1.2
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var commandSpaceDate: Date?
    private var lastTriggerDate: Date?
    private var action: (() -> Void)?

    func start(action: @escaping () -> Void) {
        stop()
        self.action = action

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            self?.scheduleHandling(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            self?.scheduleHandling(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        globalMonitor = nil
        localMonitor = nil
        commandSpaceDate = nil
        action = nil
    }

    nonisolated private func scheduleHandling(_ event: NSEvent) {
        let keyCode = event.keyCode
        let commandPressed = event.modifierFlags.contains(.command)
        let isARepeat = event.isARepeat

        Task { @MainActor [weak self] in
            self?.handle(
                keyCode: keyCode,
                commandPressed: commandPressed,
                isARepeat: isARepeat
            )
        }
    }

    private func handle(
        keyCode: UInt16,
        commandPressed: Bool,
        isARepeat: Bool
    ) {
        guard !isARepeat else {
            return
        }

        let now = Date()

        if keyCode == KeyCode.space, commandPressed {
            commandSpaceDate = now
            return
        }

        guard keyCode == KeyCode.b,
              let commandSpaceDate,
              now.timeIntervalSince(commandSpaceDate) <= sequenceTimeout else {
            if let commandSpaceDate,
               now.timeIntervalSince(commandSpaceDate) > sequenceTimeout {
                self.commandSpaceDate = nil
            }
            return
        }

        self.commandSpaceDate = nil

        if let lastTriggerDate,
           now.timeIntervalSince(lastTriggerDate) < 0.25 {
            return
        }

        lastTriggerDate = now
        action?()
    }
}
