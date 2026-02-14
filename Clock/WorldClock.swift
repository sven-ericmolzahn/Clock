import Foundation

struct WorldClock: Identifiable, Codable, Hashable {
    var id: UUID
    var label: String
    var timeZoneIdentifier: String

    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }

    init(id: UUID = UUID(), label: String, timeZoneIdentifier: String) {
        self.id = id
        self.label = label
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}
