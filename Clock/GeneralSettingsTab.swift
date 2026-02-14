import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section("Menu Bar Format") {
                TextField("Date format pattern", text: $appState.menuBarFormat)
                Text("Preview: \(menuBarPreview)")
                    .foregroundStyle(.secondary)
            }

            Section("World Clock Format") {
                TextField("Date format pattern", text: $appState.worldClockFormat)
                Text("Preview: \(worldClockPreview)")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Show world clocks in menu bar", isOn: $appState.showWorldClocksInMenuBar)
            }

            Section {
                Text("Use Unicode date format patterns (e.g. HH:mm, yyyy-MM-dd, EEE)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var menuBarPreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = appState.menuBarFormat
        return formatter.string(from: appState.currentDate)
    }

    private var worldClockPreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = appState.worldClockFormat
        return formatter.string(from: appState.currentDate)
    }
}
