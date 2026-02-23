import Foundation
import Observation
import SwiftUI

@Observable
final class AppState {
    var worldClocks: [WorldClock] {
        didSet { saveWorldClocks() }
    }

    var menuBarFormat: String {
        didSet { defaults.set(menuBarFormat, forKey: "menuBarFormat") }
    }

    var worldClockFormat: String {
        didSet { defaults.set(worldClockFormat, forKey: "worldClockFormat") }
    }

    var worldClocksFirst: Bool {
        didSet { defaults.set(worldClocksFirst, forKey: "worldClocksFirst") }
    }

    var currentDate: Date = Date()

    let holidayService = HolidayService()

    private var timer: Timer?
    private var lastHolidayRefresh: Date = .distantPast
    private let defaults: UserDefaults

    var menuBarText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = menuBarFormat
        let localText = formatter.string(from: currentDate)

        let parts = worldClocks.filter(\.showInMenuBar).compactMap { clock -> String? in
            guard let tz = clock.timeZone else { return nil }
            formatter.timeZone = tz
            formatter.dateFormat = worldClockFormat
            return "\(clock.label) \(formatter.string(from: currentDate))"
        }

        if parts.isEmpty {
            return localText
        }

        let worldText = parts.joined(separator: " | ")
        if worldClocksFirst {
            return worldText + " | " + localText
        } else {
            return localText + " | " + worldText
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.menuBarFormat = defaults.string(forKey: "menuBarFormat") ?? "HH:mm"
        self.worldClockFormat = defaults.string(forKey: "worldClockFormat") ?? "HH:mm"
        self.worldClocksFirst = defaults.bool(forKey: "worldClocksFirst")

        if let data = defaults.data(forKey: "worldClocks"),
           let decoded = try? JSONDecoder().decode([WorldClock].self, from: data) {
            self.worldClocks = decoded
        } else {
            self.worldClocks = []
        }

        startTimer()
        refreshHolidays()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentDate = Date()

            if self.currentDate.timeIntervalSince(self.lastHolidayRefresh) > 60 * 60 {
                self.lastHolidayRefresh = self.currentDate
                self.refreshHolidays()
            }
        }
    }

    private func saveWorldClocks() {
        if let data = try? JSONEncoder().encode(worldClocks) {
            defaults.set(data, forKey: "worldClocks")
        }
    }

    func addWorldClock(label: String, timeZoneIdentifier: String, countryCode: String? = nil) {
        let clock = WorldClock(label: label, timeZoneIdentifier: timeZoneIdentifier, countryCode: countryCode)
        worldClocks.append(clock)
        holidayService.fetchIfNeeded(for: clock)
    }

    func removeWorldClocks(at offsets: IndexSet) {
        worldClocks.remove(atOffsets: offsets)
    }

    func moveWorldClocks(from source: IndexSet, to destination: Int) {
        worldClocks.move(fromOffsets: source, toOffset: destination)
    }

    func refreshHolidays() {
        for clock in worldClocks {
            holidayService.fetchIfNeeded(for: clock)
        }
    }
}
