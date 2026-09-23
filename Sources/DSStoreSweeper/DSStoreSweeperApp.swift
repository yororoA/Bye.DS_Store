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
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text("Bye")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bye.DS_Store")
        .help("Bye.DS_Store")
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
