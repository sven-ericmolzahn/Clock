import SwiftUI

struct WorldClockRow: View {
    @Environment(AppState.self) private var appState
    let clock: WorldClock
    var overrideDate: Date? = nil

    private var displayDate: Date {
        overrideDate ?? appState.currentDate
    }

    private var isConverting: Bool {
        overrideDate != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            // Flag + day/night icon
            VStack(spacing: 2) {
                Text(clock.flagEmoji ?? "🌐")
                    .font(.title3)
                Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.caption2)
                    .foregroundStyle(isDaytime ? .yellow : .indigo)
            }
            .frame(width: 30)

            // Label, offset, day badge, holiday
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(clock.label)
                        .font(.headline)
                    if let badge = dayBadge {
                        Text(badge)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.7), in: Capsule())
                    }
                }
                Text(utcOffsetText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !isConverting, let holiday = nextHoliday {
                    Text("\(holidayDateText(holiday.date)) — \(holiday.localName)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Text(formattedTime)
                .font(.system(.title2, design: .monospaced))
                .foregroundStyle(isConverting ? Color.accentColor : .primary)
        }
        .onAppear {
            appState.holidayService.fetchIfNeeded(for: clock)
        }
    }

    // MARK: - Day/Night

    private var isDaytime: Bool {
        guard let tz = clock.timeZone else { return true }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: tz, from: displayDate)
        let hour = components.hour ?? 12
        return hour >= 6 && hour < 20
    }

    // MARK: - Tomorrow/Yesterday badge

    private var dayBadge: String? {
        guard let tz = clock.timeZone else { return nil }
        let calendar = Calendar.current
        let referenceDate = isConverting ? displayDate : appState.currentDate
        let localDay = calendar.startOfDay(for: referenceDate)
        let remoteComponents = calendar.dateComponents(in: tz, from: referenceDate)
        guard let remoteDate = calendar.date(from: remoteComponents) else { return nil }
        let remoteDay = calendar.startOfDay(for: remoteDate)
        let diff = calendar.dateComponents([.day], from: localDay, to: remoteDay).day ?? 0
        switch diff {
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default: return nil
        }
    }

    // MARK: - Helpers

    private var nextHoliday: PublicHoliday? {
        appState.holidayService.nextHoliday(for: clock)
    }

    private var formattedTime: String {
        guard let tz = clock.timeZone else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = appState.worldClockFormat
        formatter.timeZone = tz
        return formatter.string(from: displayDate)
    }

    private var utcOffsetText: String {
        guard let tz = clock.timeZone else { return "" }
        let localOffset = TimeZone.current.secondsFromGMT(for: displayDate)
        let remoteOffset = tz.secondsFromGMT(for: displayDate)
        let diff = (remoteOffset - localOffset) / 3600
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(diff)h from local"
    }

    private func holidayDateText(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = inputFormatter.date(from: dateString) else { return dateString }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMM"
            return outputFormatter.string(from: date)
        }
    }
}
