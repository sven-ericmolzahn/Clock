import Foundation

struct PublicHoliday: Codable, Sendable {
    var date: String
    var localName: String
    var name: String
    var countryCode: String
}

@Observable
final class HolidayService {
    var nextHolidays: [String: PublicHoliday] = [:]

    private var cache: [String: [PublicHoliday]] = [:]
    private var inFlight: Set<String> = []

    private static let timeZoneToCountry: [String: String] = {
        guard let contents = try? String(contentsOfFile: "/usr/share/zoneinfo/zone.tab", encoding: .utf8) else {
            return [:]
        }
        var mapping: [String: String] = [:]
        for line in contents.components(separatedBy: "\n") {
            guard !line.hasPrefix("#"), !line.isEmpty else { continue }
            let fields = line.components(separatedBy: "\t")
            guard fields.count >= 3 else { continue }
            mapping[fields[2]] = fields[0]
        }
        return mapping
    }()

    static func countryCode(for timeZoneIdentifier: String) -> String? {
        timeZoneToCountry[timeZoneIdentifier]
    }

    func resolveCountryCode(for clock: WorldClock) -> String? {
        if let code = clock.countryCode { return code }
        return Self.countryCode(for: clock.timeZoneIdentifier)
    }

    func nextHoliday(for clock: WorldClock) -> PublicHoliday? {
        guard let code = resolveCountryCode(for: clock)?.uppercased() else { return nil }
        return nextHolidays[code]
    }

    func fetchIfNeeded(for clock: WorldClock) {
        guard let code = resolveCountryCode(for: clock)?.uppercased(), !code.isEmpty else { return }
        guard cache[code] == nil, !inFlight.contains(code) else { return }
        inFlight.insert(code)

        Task {
            await fetch(countryCode: code)
        }
    }

    private func fetch(countryCode: String) async {
        guard let url = URL(string: "https://date.nager.at/api/v3/NextPublicHolidays/\(countryCode)") else {
            inFlight.remove(countryCode)
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                inFlight.remove(countryCode)
                return
            }

            let decoder = JSONDecoder()
            let holidays = try decoder.decode([PublicHoliday].self, from: data)
            cache[countryCode] = holidays
            if let first = holidays.first {
                nextHolidays[countryCode] = first
            }
        } catch {
            // Silently fail — holidays are optional info
        }
        inFlight.remove(countryCode)
    }
}
