import SwiftUI

@main
struct DSStoreSweeperApp: App {
    @NSApplicationDelegateAdaptor(MenuBarController.self)
    private var menuBarController: MenuBarController

    var body: some Scene {
        Settings {
            SettingsView(model: menuBarController.model)
        }
    }
}
