import AppKit
import Combine
import ApplicationServices
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSApplicationDelegate {
    let model: SweeperAppModel

    private let shortcutMonitor = GlobalShortcutMonitor()
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?

    override init() {
        model = SweeperAppModel()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePanel()

        requestAccessibilityPermission()
        shortcutMonitor.start { [weak self] in
            self?.showPanelFromShortcut()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutMonitor.stop()
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "sparkles",
            accessibilityDescription: "Bye.DS_Store"
        )
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.toolTip = "Bye.DS_Store"
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
        self.statusItem = statusItem
        updateStatusIcon()
    }

    private func configurePanel() {
        let rootView = SweeperMenuView(
            model: model,
            onOpenSettings: { [weak self] in
                self?.openSettings()
            }
        )
        let hostingController = NSHostingController(rootView: rootView)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hostingController
        panel.title = "Bye.DS_Store"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.panel = panel

        model.$finderAccessState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
            .store(in: &cancellables)
    }

    @objc
    private func togglePanel() {
        guard let panel else {
            return
        }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel(panel)
        }
    }

    private func showPanelFromShortcut() {
        guard let panel else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        showPanel(panel)
    }

    private func showPanel(_ panel: NSPanel) {
        if let screen = NSScreen.main {
            let panelSize = panel.frame.size
            let origin = NSPoint(
                x: screen.visibleFrame.midX - panelSize.width / 2,
                y: screen.visibleFrame.midY - panelSize.height / 2
            )
            panel.setFrameOrigin(origin)
        }

        panel.makeKeyAndOrderFront(nil)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )
    }

    private func requestAccessibilityPermission() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func updateStatusIcon() {
        let iconName: String

        switch model.finderAccessState {
        case .denied, .failed:
            iconName = "exclamationmark.triangle"
        case .unknown, .allowed:
            iconName = model.settings.isMonitoringEnabled ? "sparkles" : "pause.circle"
        }

        statusItem?.button?.image = NSImage(
            systemSymbolName: iconName,
            accessibilityDescription: "Bye.DS_Store"
        )
        statusItem?.button?.image?.isTemplate = true
    }

    private var cancellables = Set<AnyCancellable>()
}
