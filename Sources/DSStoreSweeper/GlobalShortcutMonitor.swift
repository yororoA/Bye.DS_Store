import Carbon.HIToolbox
import Foundation

final class GlobalShortcutMonitor: @unchecked Sendable {
    private static let hotKeySignature: OSType = 0x42594453
    private static let hotKeyIdentifier: UInt32 = 1

    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?
    private var action: (@MainActor @Sendable () -> Void)?

    func start(action: @escaping @MainActor @Sendable () -> Void) {
        stop()
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.hotKeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard handlerStatus == noErr else {
            return
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.hotKeySignature,
            id: Self.hotKeyIdentifier
        )
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_B),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )

        if registerStatus != noErr {
            stop()
        }
    }

    func stop() {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }

        hotKey = nil
        eventHandler = nil
        action = nil
    }

    private func trigger() {
        Task { @MainActor [weak self] in
            self?.action?()
        }
    }

    private static let hotKeyEventHandler: EventHandlerUPP = {
        _, _, userData in
        guard let userData else {
            return OSStatus(eventNotHandledErr)
        }

        let monitor = Unmanaged<GlobalShortcutMonitor>
            .fromOpaque(userData)
            .takeUnretainedValue()
        monitor.trigger()
        return noErr
    }
}
