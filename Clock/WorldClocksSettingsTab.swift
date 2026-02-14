import SwiftUI

struct WorldClocksSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            if appState.worldClocks.isEmpty {
                ContentUnavailableView(
                    "No World Clocks",
                    systemImage: "globe",
                    description: Text("Click the map below to add a world clock.")
                )
            } else {
                List {
                    ForEach($appState.worldClocks) { $clock in
                        WorldClockCard(
                            clock: $clock,
                            onDelete: {
                                if let index = appState.worldClocks.firstIndex(where: { $0.id == clock.id }) {
                                    withAnimation(.snappy) {
                                        appState.removeWorldClocks(at: IndexSet(integer: index))
                                    }
                                }
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }
                    .onMove { source, destination in
                        appState.moveWorldClocks(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            MapTimeZonePicker()
        }
    }
}

private struct WorldClockCard: View {
    @Binding var clock: WorldClock
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(clock.flagEmoji ?? "🌐")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Label", text: $clock.label)
                        .font(.system(.body, weight: .semibold))
                        .textFieldStyle(.plain)
                    Text(friendlyTimezone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 18)
                        .background(.fill.tertiary, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Divider()

            Toggle(isOn: $clock.showInMenuBar) {
                Label("Show in Menu Bar", systemImage: "menubar.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(10)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var friendlyTimezone: String {
        guard let tz = clock.timeZone else { return clock.timeZoneIdentifier }
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60 % 60)
        let sign = hours >= 0 ? "+" : ""
        let utc = minutes == 0 ? "UTC\(sign)\(hours)" : "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
        return utc
    }
}
