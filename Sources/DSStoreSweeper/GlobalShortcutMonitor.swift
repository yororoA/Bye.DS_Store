import AppKit
import Foundation

@MainActor
final class GlobalShortcutMonitor {
    private enum KeyCode {
        static let b: UInt16 = 11
    }

    private var globalMonitor: Any?
    private var localMonitor: Any?
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
        action = nil
    }

    nonisolated private func scheduleHandling(_ event: NSEvent) {
        let keyCode = event.keyCode
        let commandOptionPressed = event.modifierFlags.contains(.command)
            && event.modifierFlags.contains(.option)
        let isARepeat = event.isARepeat

        Task { @MainActor [weak self] in
            self?.handle(
                keyCode: keyCode,
                commandOptionPressed: commandOptionPressed,
                isARepeat: isARepeat
            )
        }
    }

    private func handle(
        keyCode: UInt16,
        commandOptionPressed: Bool,
        isARepeat: Bool
    ) {
        guard !isARepeat,
              keyCode == KeyCode.b,
              commandOptionPressed else {
            return
        }

        let now = Date()

        if let lastTriggerDate,
           now.timeIntervalSince(lastTriggerDate) < 0.25 {
            return
        }

        lastTriggerDate = now
        action?()
    }
}
