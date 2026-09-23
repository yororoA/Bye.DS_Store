import SwiftUI

@main
struct DSStoreSweeperApp: App {
    @StateObject private var model: SweeperAppModel

    init() {
        _model = StateObject(wrappedValue: SweeperAppModel())
    }

    var body: some Scene {
        MenuBarExtra {
            SweeperMenuView(model: model)
        } label: {
            MenuBarLabel(model: model, settings: model.settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var model: SweeperAppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        Label("Bye.DS_Store", systemImage: iconName)
    }

    private var iconName: String {
        switch model.finderAccessState {
        case .denied, .failed:
            return "exclamationmark.triangle"
        case .unknown, .allowed:
            return settings.isMonitoringEnabled ? "sparkles" : "pause.circle"
        }
    }
}
