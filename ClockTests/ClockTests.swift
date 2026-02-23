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

    // MARK: - WorldClock: resolvedCountryCode

    @Test func worldClockResolvedCountryCodeExplicit() {
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo", countryCode: "JP")
        #expect(clock.resolvedCountryCode == "JP")
    }

    @Test func worldClockResolvedCountryCodeFromZoneTab() {
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        #expect(clock.resolvedCountryCode == "JP")
    }

    @Test func worldClockResolvedCountryCodeInvalidZone() {
        let clock = WorldClock(label: "Nowhere", timeZoneIdentifier: "Invalid/Zone")
        #expect(clock.resolvedCountryCode == nil)
    }

    // MARK: - WorldClock: flagEmoji

    @Test func worldClockFlagEmojiJapan() {
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo", countryCode: "JP")
        #expect(clock.flagEmoji == "🇯🇵")
    }

    @Test func worldClockFlagEmojiUSA() {
        let clock = WorldClock(label: "New York", timeZoneIdentifier: "America/New_York", countryCode: "US")
        #expect(clock.flagEmoji == "🇺🇸")
    }

    @Test func worldClockFlagEmojiNilForInvalidZone() {
        let clock = WorldClock(label: "Nowhere", timeZoneIdentifier: "Invalid/Zone")
        #expect(clock.flagEmoji == nil)
    }

    // MARK: - WorldClock: showInMenuBar default

    @Test func worldClockShowInMenuBarDefaultsFalse() {
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        #expect(clock.showInMenuBar == false)
    }

    // MARK: - AppState: menuBarText with world clocks

    @Test func appStateMenuBarTextIncludesWorldClocks() {
        let state = AppState(defaults: freshDefaults())
        state.menuBarFormat = "HH:mm"
        state.worldClockFormat = "HH:mm"
        state.addWorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        state.worldClocks[0].showInMenuBar = true

        let text = state.menuBarText
        #expect(text.contains("Tokyo"))
        #expect(text.contains("|"))
    }

    @Test func appStateMenuBarTextExcludesHiddenClocks() {
        let state = AppState(defaults: freshDefaults())
        state.addWorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        // showInMenuBar defaults to false
        let text = state.menuBarText
        #expect(!text.contains("Tokyo"))
    }

    // MARK: - AppState: persistence

    @Test func appStatePersistsWorldClocks() {
        let defaults = freshDefaults()
        let state = AppState(defaults: defaults)
        state.addWorldClock(label: "Berlin", timeZoneIdentifier: "Europe/Berlin")

        let state2 = AppState(defaults: defaults)
        #expect(state2.worldClocks.count == 1)
        #expect(state2.worldClocks[0].label == "Berlin")
        #expect(state2.worldClocks[0].timeZoneIdentifier == "Europe/Berlin")
    }

    @Test func appStatePersistsFormats() {
        let defaults = freshDefaults()
        let state = AppState(defaults: defaults)
        state.menuBarFormat = "HH:mm:ss"
        state.worldClockFormat = "h:mm a"

        let state2 = AppState(defaults: defaults)
        #expect(state2.menuBarFormat == "HH:mm:ss")
        #expect(state2.worldClockFormat == "h:mm a")
    }

    // MARK: - AppState: worldClocksFirst

    @Test func appStateWorldClocksAfterLocalByDefault() {
        let state = AppState(defaults: freshDefaults())
        state.menuBarFormat = "HH:mm"
        state.worldClockFormat = "HH:mm"
        state.addWorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        state.worldClocks[0].showInMenuBar = true

        let text = state.menuBarText
        let localRange = text.startIndex
        let tokyoRange = text.range(of: "Tokyo")!
        #expect(localRange < tokyoRange.lowerBound)
    }

    @Test func appStateWorldClocksBeforeLocalWhenEnabled() {
        let state = AppState(defaults: freshDefaults())
        state.menuBarFormat = "HH:mm"
        state.worldClockFormat = "HH:mm"
        state.worldClocksFirst = true
        state.addWorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        state.worldClocks[0].showInMenuBar = true

        let text = state.menuBarText
        let tokyoRange = text.range(of: "Tokyo")!
        // The local time is the last segment after the final " | "
        let lastSeparator = text.range(of: " | ", options: .backwards)!
        #expect(tokyoRange.lowerBound < lastSeparator.lowerBound)
    }

    @Test func appStatePersistsWorldClocksFirst() {
        let defaults = freshDefaults()
        let state = AppState(defaults: defaults)
        state.worldClocksFirst = true

        let state2 = AppState(defaults: defaults)
        #expect(state2.worldClocksFirst == true)
    }

    // MARK: - HolidayService: countryCode

    @Test func holidayServiceCountryCodeForKnownZone() {
        #expect(HolidayService.countryCode(for: "Asia/Tokyo") == "JP")
        #expect(HolidayService.countryCode(for: "Europe/Berlin") == "DE")
        #expect(HolidayService.countryCode(for: "America/New_York") == "US")
    }

    @Test func holidayServiceCountryCodeForUnknownZone() {
        #expect(HolidayService.countryCode(for: "Invalid/Zone") == nil)
    }

    // MARK: - HolidayService: resolveCountryCode

    @Test func holidayServiceResolveCountryCodePrefersExplicit() {
        let service = HolidayService()
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo", countryCode: "DE")
        #expect(service.resolveCountryCode(for: clock) == "DE")
    }

    @Test func holidayServiceResolveCountryCodeFallsBackToZoneTab() {
        let service = HolidayService()
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        #expect(service.resolveCountryCode(for: clock) == "JP")
    }

    // MARK: - HolidayService: nextHoliday

    @Test func holidayServiceNextHolidayReturnsNilWhenEmpty() {
        let service = HolidayService()
        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        #expect(service.nextHoliday(for: clock) == nil)
    }

    @Test func holidayServiceNextHolidayReturnsStoredHoliday() {
        let service = HolidayService()
        let holiday = PublicHoliday(date: "2026-01-01", localName: "元日", name: "New Year's Day", countryCode: "JP")
        service.nextHolidays["JP"] = holiday

        let clock = WorldClock(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        let result = service.nextHoliday(for: clock)
        #expect(result?.name == "New Year's Day")
        #expect(result?.localName == "元日")
    }

    // MARK: - MenuBarPanel: parseTime

    @Test func parseTime24Hour() {
        let ref = makeDate(hour: 12, minute: 0)
        let result = MenuBarPanel.parseTime("15:30", relativeTo: ref)
        #expect(result != nil)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: result!)
        #expect(comps.hour == 15)
        #expect(comps.minute == 30)
    }

    @Test func parseTimeSingleDigitHour() {
        let ref = makeDate(hour: 12, minute: 0)
        let result = MenuBarPanel.parseTime("9:05", relativeTo: ref)
        #expect(result != nil)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: result!)
        #expect(comps.hour == 9)
        #expect(comps.minute == 5)
    }

    @Test func parseTimeDotSeparator() {
        let ref = makeDate(hour: 12, minute: 0)
        let result = MenuBarPanel.parseTime("14.45", relativeTo: ref)
        #expect(result != nil)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: result!)
        #expect(comps.hour == 14)
        #expect(comps.minute == 45)
    }

    @Test func parseTimeBareNumber() {
        let ref = makeDate(hour: 12, minute: 0)
        let result = MenuBarPanel.parseTime("9", relativeTo: ref)
        #expect(result != nil)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: result!)
        #expect(comps.hour == 9)
        #expect(comps.minute == 0)
    }

    @Test func parseTimeBareNumberBoundary() {
        let ref = makeDate(hour: 12, minute: 0)
        #expect(MenuBarPanel.parseTime("0", relativeTo: ref) != nil)
        #expect(MenuBarPanel.parseTime("23", relativeTo: ref) != nil)
        #expect(MenuBarPanel.parseTime("24", relativeTo: ref) == nil)
        #expect(MenuBarPanel.parseTime("-1", relativeTo: ref) == nil)
    }

    @Test func parseTimeInvalidInput() {
        let ref = makeDate(hour: 12, minute: 0)
        #expect(MenuBarPanel.parseTime("abc", relativeTo: ref) == nil)
    }

    @Test func parseTimeCompactFormat() {
        let ref = makeDate(hour: 12, minute: 0)
        let result = MenuBarPanel.parseTime("1430", relativeTo: ref)
        #expect(result != nil)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: result!)
        #expect(comps.hour == 14)
        #expect(comps.minute == 30)
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: hour, minute: minute))!
    }
}
