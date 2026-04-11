import ServiceManagement
import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppState.self) private var appState
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private static let menuBarPresets: [(label: LocalizedStringResource, format: String)] = [
        ("Time", "HH:mm"),
        ("12-hour", "h:mm a"),
        ("Seconds", "HH:mm:ss"),
        ("Weekday", "EEE HH:mm"),
        ("Cal week", "'W'w · EEE HH:mm"),
        ("Date", "dd MMM HH:mm"),
        ("ISO date", "yyyy-MM-dd HH:mm"),
        ("Full", "EEEE, d MMMM"),
    ]

    private static let worldClockPresets: [(label: LocalizedStringResource, format: String)] = [
        ("Time", "HH:mm"),
        ("12-hour", "h:mm a"),
        ("Seconds", "HH:mm:ss"),
        ("Weekday", "EEE HH:mm"),
    ]

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section("Menu Bar Format") {
                FormatBuilderView(
                    formatString: $appState.menuBarFormat,
                    presets: Self.menuBarPresets,
                    currentDate: appState.currentDate
                )
            }

            Section {
                Toggle("Show world clocks before local time", isOn: $appState.worldClocksFirst)
            }

            Section("World Clock Format") {
                FormatBuilderView(
                    formatString: $appState.worldClockFormat,
                    presets: Self.worldClockPresets,
                    currentDate: appState.currentDate
                )
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
