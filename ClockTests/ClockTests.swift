import Testing
import Foundation
@testable import Clock

struct ClockTests {

    private func freshDefaults() -> UserDefaults {
        let name = "ClockTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func worldClockRoundtrip() throws {
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        let data = try JSONEncoder().encode(clock)
        let decoded = try JSONDecoder().decode(WorldClock.self, from: data)
        #expect(decoded.id == clock.id)
        #expect(decoded.label == "Tokyo")
        #expect(decoded.timeZoneIdentifier == "Asia/Tokyo")
        #expect(decoded.timeZone == TimeZone(identifier: "Asia/Tokyo"))
    }

    @Test func worldClockInvalidTimeZone() {
        let clock = WorldClock(label: "Nowhere", timeZoneIdentifier: "Invalid/Zone")
        #expect(clock.timeZone == nil)
    }

    @Test func appStateDefaultFormats() {
        let state = AppState(defaults: freshDefaults())
        #expect(state.menuBarFormat == "HH:mm")
        #expect(state.worldClockFormat == "HH:mm")
        #expect(state.worldClocks.isEmpty)
    }

    @Test func appStateMenuBarText() {
        let state = AppState(defaults: freshDefaults())
        state.menuBarFormat = "HH:mm"
        let text = state.menuBarText
        #expect(!text.isEmpty)
    }

    @Test func appStateAddRemoveClocks() {
        let state = AppState(defaults: freshDefaults())
        state.addWorldClock(label: "London", timeZoneIdentifier: "Europe/London")
        #expect(state.worldClocks.count == 1)
        #expect(state.worldClocks[0].label == "London")

        state.addWorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        #expect(state.worldClocks.count == 2)

        state.removeWorldClocks(at: IndexSet(integer: 0))
        #expect(state.worldClocks.count == 1)
        #expect(state.worldClocks[0].label == "Tokyo")
    }

    @Test func appStateMoveClocks() {
        let state = AppState(defaults: freshDefaults())
        state.addWorldClock(label: "A", timeZoneIdentifier: "Europe/London")
        state.addWorldClock(label: "B", timeZoneIdentifier: "Asia/Tokyo")
        state.addWorldClock(label: "C", timeZoneIdentifier: "America/New_York")

        state.moveWorldClocks(from: IndexSet(integer: 0), to: 3)
        #expect(state.worldClocks[0].label == "B")
        #expect(state.worldClocks[2].label == "A")
    }
}
