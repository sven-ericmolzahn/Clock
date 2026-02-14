import SwiftUI

struct MenuBarPanel: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 12) {
            LocalClockView()

            if !appState.worldClocks.isEmpty {
                Divider()
                ForEach(appState.worldClocks) { clock in
                    WorldClockRow(clock: clock)
                }
            }

            Divider()

            HStack {
                SettingsLink {
                    Text("Settings...")
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 280)
    }
}
