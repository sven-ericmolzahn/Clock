import SwiftUI

@main
struct ClockApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .environment(appState)
        } label: {
            Text(appState.menuBarText)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
