import Foundation
import Observation
import SwiftUI

@Observable
final class AppState {
    var worldClocks: [WorldClock] {
        didSet { saveWorldClocks() }
    }

    var menuBarFormat: String {
        didSet { UserDefaults.standard.set(menuBarFormat, forKey: "menuBarFormat") }
    }

    var worldClockFormat: String {
        didSet { UserDefaults.standard.set(worldClockFormat, forKey: "worldClockFormat") }
    }

    var showWorldClocksInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showWorldClocksInMenuBar, forKey: "showWorldClocksInMenuBar") }
    }

    var currentDate: Date = Date()

    private var timer: Timer?

    var menuBarText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = menuBarFormat
        var text = formatter.string(from: currentDate)

        if showWorldClocksInMenuBar {
            let parts = worldClocks.compactMap { clock -> String? in
                guard let tz = clock.timeZone else { return nil }
                formatter.timeZone = tz
                formatter.dateFormat = worldClockFormat
                return "\(clock.label) \(formatter.string(from: currentDate))"
            }
            if !parts.isEmpty {
                text += " | " + parts.joined(separator: " | ")
            }
        }

        return text
    }

    init() {
        let defaults = UserDefaults.standard

        self.menuBarFormat = defaults.string(forKey: "menuBarFormat") ?? "HH:mm"
        self.worldClockFormat = defaults.string(forKey: "worldClockFormat") ?? "HH:mm"
        self.showWorldClocksInMenuBar = defaults.bool(forKey: "showWorldClocksInMenuBar")

        if let data = defaults.data(forKey: "worldClocks"),
           let decoded = try? JSONDecoder().decode([WorldClock].self, from: data) {
            self.worldClocks = decoded
        } else {
            self.worldClocks = []
        }

        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }

    private func saveWorldClocks() {
        if let data = try? JSONEncoder().encode(worldClocks) {
            UserDefaults.standard.set(data, forKey: "worldClocks")
        }
    }

    func addWorldClock(label: String, timeZoneIdentifier: String) {
        worldClocks.append(WorldClock(label: label, timeZoneIdentifier: timeZoneIdentifier))
    }

    func removeWorldClocks(at offsets: IndexSet) {
        worldClocks.remove(atOffsets: offsets)
    }

    func moveWorldClocks(from source: IndexSet, to destination: Int) {
        worldClocks.move(fromOffsets: source, toOffset: destination)
    }
}
