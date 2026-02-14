import SwiftUI

struct WorldClocksSettingsTab: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTimeZone = TimeZone.knownTimeZoneIdentifiers.first ?? ""
    @State private var label = ""

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(appState.worldClocks) { clock in
                    HStack {
                        Text(clock.label)
                            .fontWeight(.medium)
                        Spacer()
                        Text(clock.timeZoneIdentifier)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    appState.removeWorldClocks(at: offsets)
                }
                .onMove { source, destination in
                    appState.moveWorldClocks(from: source, to: destination)
                }
            }

            Divider()

            HStack {
                TextField("Label", text: $label)
                    .frame(width: 100)
                Picker("Time Zone", selection: $selectedTimeZone) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
                .labelsHidden()
                Button("Add") {
                    let clockLabel = label.isEmpty ? selectedTimeZone : label
                    appState.addWorldClock(label: clockLabel, timeZoneIdentifier: selectedTimeZone)
                    label = ""
                }
            }
            .padding()
        }
    }
}
