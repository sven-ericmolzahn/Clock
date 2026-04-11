import SwiftUI

struct CalendarView: View {
    @Environment(AppState.self) private var appState

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    private var currentMonth: Int {
        calendar.component(.month, from: appState.currentDate)
    }

    private var today: Date {
        calendar.startOfDay(for: appState.currentDate)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(monthYearString)
                .font(.headline)

            Grid(horizontalSpacing: 0, verticalSpacing: 2) {
                // Header row
                GridRow {
                    Text("CW")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(dayNames, id: \.self) { name in
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                // Week rows
                ForEach(weeks, id: \.first) { week in
                    GridRow {
                        Text("\(calendar.component(.weekOfYear, from: week.first!))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(week, id: \.self) { date in
                            dayCell(for: date)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isCurrentMonth = calendar.component(.month, from: date) == currentMonth
        let isToday = calendar.isDate(date, inSameDayAs: today)

        return Text("\(day)")
            .font(.system(.body, design: .default))
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(isToday ? .white : (isCurrentMonth ? .primary : .secondary.opacity(0.5)))
            .frame(width: 28, height: 28)
            .background {
                if isToday {
                    Circle().fill(.red)
                }
            }
    }

    // MARK: - Data

    private var weeks: [[Date]] {
        let year = calendar.component(.year, from: appState.currentDate)
        let month = currentMonth

        let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth)!

        // Monday on or before the 1st
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let mondayOffset = (weekday - 2 + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -mondayOffset, to: firstOfMonth)!

        // Sunday on or after the last day
        let lastWeekday = calendar.component(.weekday, from: lastOfMonth)
        let sundayOffset = (8 - lastWeekday) % 7
        let gridEnd = calendar.date(byAdding: .day, value: sundayOffset, to: lastOfMonth)!

        let totalDays = calendar.dateComponents([.day], from: gridStart, to: gridEnd).day! + 1

        var rows: [[Date]] = []
        for weekIndex in stride(from: 0, to: totalDays, by: 7) {
            var row: [Date] = []
            for dayIndex in 0..<7 {
                row.append(calendar.date(byAdding: .day, value: weekIndex + dayIndex, to: gridStart)!)
            }
            rows.append(row)
        }
        return rows
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Locale.preferredLanguages[0])
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: appState.currentDate)
    }

    private var dayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Locale.preferredLanguages[0])
        let symbols = formatter.shortStandaloneWeekdaySymbols!
        // Reorder from [Sun, Mon, ...] to [Mon, Tue, ..., Sun]
        return Array(symbols[1...]) + [symbols[0]]
    }
}
