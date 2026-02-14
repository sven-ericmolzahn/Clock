import SwiftUI

struct LocalClockView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 4) {
            Text(formattedTime)
                .font(.system(size: 36, weight: .light, design: .monospaced))
            Text(formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = appState.menuBarFormat
        return formatter.string(from: appState.currentDate)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: appState.currentDate)
    }
}
