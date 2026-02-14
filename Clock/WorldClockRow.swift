import SwiftUI

struct WorldClockRow: View {
    @Environment(AppState.self) private var appState
    let clock: WorldClock

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(clock.label)
                    .font(.headline)
                Text(utcOffsetText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formattedTime)
                .font(.system(.title2, design: .monospaced))
        }
    }

    private var formattedTime: String {
        guard let tz = clock.timeZone else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = appState.worldClockFormat
        formatter.timeZone = tz
        return formatter.string(from: appState.currentDate)
    }

    private var utcOffsetText: String {
        guard let tz = clock.timeZone else { return "" }
        let localOffset = TimeZone.current.secondsFromGMT(for: appState.currentDate)
        let remoteOffset = tz.secondsFromGMT(for: appState.currentDate)
        let diff = (remoteOffset - localOffset) / 3600
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(diff)h from local"
    }
}
