import Foundation

struct WorldClock: Identifiable, Codable, Hashable {
    var id: UUID
    var label: String
    var timeZoneIdentifier: String
    var countryCode: String?
    var showInMenuBar: Bool

    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }

    var resolvedCountryCode: String? {
        countryCode ?? HolidayService.countryCode(for: timeZoneIdentifier)
    }

    var flagEmoji: String? {
        guard let code = resolvedCountryCode?.uppercased(), code.count == 2 else { return nil }
        let scalars = code.unicodeScalars.compactMap { Unicode.Scalar(0x1F1E6 + $0.value - 0x41) }
        guard scalars.count == 2 else { return nil }
        return String(scalars.map { Character($0) })
    }

    init(id: UUID = UUID(), label: String, timeZoneIdentifier: String, countryCode: String? = nil, showInMenuBar: Bool = false) {
        self.id = id
        self.label = label
        self.timeZoneIdentifier = timeZoneIdentifier
        self.countryCode = countryCode
        self.showInMenuBar = showInMenuBar
    }
}
