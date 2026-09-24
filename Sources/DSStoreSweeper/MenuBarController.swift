import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSApplicationDelegate {
    let model: SweeperAppModel

    private let shortcutMonitor = GlobalShortcutMonitor()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var fallbackPanel: NSPanel?
    private var settingsWindow: NSWindow?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?

    override init() {
        model = SweeperAppModel()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        configureOutsideClickHandling()

        shortcutMonitor.start { [weak self] in
            self?.showControlPanelFromShortcut()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutMonitor.stop()
        removeOutsideClickHandling()
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
        statusItem.button?.action = #selector(togglePopover)
        self.statusItem = statusItem
        updateStatusIcon()
    }

    private func configurePopover() {
        let rootView = SweeperMenuView(
            model: model,
            onOpenSettings: { [weak self] in
                self?.openSettings()
            }
        )
        let hostingController = NSHostingController(rootView: rootView)
        let popover = NSPopover()
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true
        self.popover = popover

        model.$finderAccessState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
            .store(in: &cancellables)

        model.settings.$isMonitoringEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
            .store(in: &cancellables)
    }

    private func configureOutsideClickHandling() {
        let mouseEvents: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown
        ]

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: mouseEvents
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.closePopoverFromOutsideClick(event)
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: mouseEvents
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.closePopoverFromOutsideClick(event)
            }
            return event
        }
    }

    private func removeOutsideClickHandling() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }

        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }

        globalClickMonitor = nil
        localClickMonitor = nil
    }

    private func closePopoverFromOutsideClick(_ event: NSEvent) {
        guard let popover,
              popover.isShown else {
            return
        }

        let eventWindow = event.window
        let popoverWindow = popover.contentViewController?.view.window
        let statusWindow = statusItem?.button?.window

        if eventWindow !== popoverWindow,
           eventWindow !== statusWindow {
            popover.performClose(nil)
        }
    }

    @objc
    private func togglePopover() {
        guard let popover,
              let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }

    private func showControlPanelFromShortcut() {
        NSApp.activate(ignoringOtherApps: true)

        if let popover,
           let button = statusItem?.button,
           button.window != nil {
            if !popover.isShown {
                popover.show(
                    relativeTo: button.bounds,
                    of: button,
                    preferredEdge: .minY
                )
            }
        } else {
            showFallbackPanel()
        }
    }

    private func showFallbackPanel() {
        if fallbackPanel == nil {
            let rootView = SweeperMenuView(
                model: model,
                onOpenSettings: { [weak self] in
                    self?.openSettings()
                }
            )
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
                styleMask: [.titled, .closable, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            panel.contentViewController = NSHostingController(rootView: rootView)
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
            fallbackPanel = panel
        }

        guard let fallbackPanel else {
            return
        }

        if let screen = NSScreen.main {
            let panelSize = fallbackPanel.frame.size
            let origin = NSPoint(
                x: screen.visibleFrame.midX - panelSize.width / 2,
                y: screen.visibleFrame.midY - panelSize.height / 2
            )
            fallbackPanel.setFrameOrigin(origin)
        }

        fallbackPanel.makeKeyAndOrderFront(nil)
    }

    private func openSettings() {
        popover?.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)

        if settingsWindow == nil {
            let settingsView = SettingsView(model: model)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 720),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = NSHostingController(rootView: settingsView)
            window.title = "Bye.DS_Store 设置"
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
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
