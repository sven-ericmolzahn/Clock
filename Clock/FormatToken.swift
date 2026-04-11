import Foundation

enum FormatTokenCategory {
    case time, date, separator
}

enum FormatTokenKind: Hashable, Sendable {
    // Time
    case hours24, hours12, minutes, seconds, ampm
    // Date
    case dayOfMonth, dayPadded, weekdayShort, weekdayFull
    case monthShort, monthFull, monthNumeric
    case yearFull, yearShort, calendarWeek
    // Separators
    case colon, dot, dash, slash, space, middleDot, comma
    // Fallback for unrecognized patterns
    case customLiteral(String)

    var icuPattern: String {
        switch self {
        case .hours24: "HH"
        case .hours12: "h"
        case .minutes: "mm"
        case .seconds: "ss"
        case .ampm: "a"
        case .dayOfMonth: "d"
        case .dayPadded: "dd"
        case .weekdayShort: "EEE"
        case .weekdayFull: "EEEE"
        case .monthShort: "MMM"
        case .monthFull: "MMMM"
        case .monthNumeric: "MM"
        case .yearFull: "yyyy"
        case .yearShort: "yy"
        case .calendarWeek: "'W'w"
        case .colon: ":"
        case .dot: "."
        case .dash: "-"
        case .slash: "/"
        case .space: " "
        case .middleDot: " · "
        case .comma: ","
        case .customLiteral(let s): s
        }
    }

    var displayLabel: String {
        switch self {
        case .hours24: String(localized: "Hours (24h)")
        case .hours12: String(localized: "Hours (12h)")
        case .minutes: String(localized: "Minutes", comment: "Format token label")
        case .seconds: String(localized: "Seconds", comment: "Format token label")
        case .ampm: "AM/PM"
        case .dayOfMonth: String(localized: "Day", comment: "Format token label")
        case .dayPadded: String(localized: "Day (01)", comment: "Format token - zero-padded")
        case .weekdayShort: String(localized: "Weekday", comment: "Format token label")
        case .weekdayFull: String(localized: "Weekday (full)")
        case .monthShort: String(localized: "Month", comment: "Format token label")
        case .monthFull: String(localized: "Month (full)")
        case .monthNumeric: String(localized: "Month (01)", comment: "Format token - numeric")
        case .yearFull: String(localized: "Year")
        case .yearShort: String(localized: "Year (short)")
        case .calendarWeek: String(localized: "Cal week", comment: "Format token label")
        case .colon: ":"
        case .dot: "."
        case .dash: "-"
        case .slash: "/"
        case .space: String(localized: "Space", comment: "Separator token label")
        case .middleDot: " · "
        case .comma: ","
        case .customLiteral(let s): s
        }
    }

    var category: FormatTokenCategory {
        switch self {
        case .hours24, .hours12, .minutes, .seconds, .ampm: .time
        case .dayOfMonth, .dayPadded, .weekdayShort, .weekdayFull,
             .monthShort, .monthFull, .monthNumeric,
             .yearFull, .yearShort, .calendarWeek: .date
        case .colon, .dot, .dash, .slash, .space, .middleDot, .comma,
             .customLiteral: .separator
        }
    }

    /// All token kinds available in the palette, in display order.
    static let paletteTokens: [FormatTokenKind] = [
        .hours24, .hours12, .minutes, .seconds, .ampm,
        .dayOfMonth, .dayPadded, .weekdayShort, .weekdayFull,
        .monthShort, .monthFull, .monthNumeric,
        .yearFull, .yearShort, .calendarWeek,
        .colon, .dot, .dash, .slash, .space, .middleDot, .comma,
    ]

    /// Known patterns sorted by length (longest first) for greedy parsing.
    static let sortedForParsing: [(kind: FormatTokenKind, pattern: String)] = {
        paletteTokens
            .map { ($0, $0.icuPattern) }
            .sorted { $0.1.count > $1.1.count }
    }()
}

struct FormatToken: Identifiable, Hashable {
    let id: UUID
    let kind: FormatTokenKind

    init(kind: FormatTokenKind, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
    }

    /// Convert a token array to an ICU format string.
    static func icuString(from tokens: [FormatToken]) -> String {
        tokens.map(\.kind.icuPattern).joined()
    }

    /// Parse an ICU format string into tokens using greedy longest-match.
    static func parse(_ icu: String) -> [FormatToken] {
        var result: [FormatToken] = []
        var remaining = icu[...]

        while !remaining.isEmpty {
            var matched = false

            for (kind, pattern) in FormatTokenKind.sortedForParsing {
                if remaining.hasPrefix(pattern) {
                    result.append(FormatToken(kind: kind))
                    remaining = remaining.dropFirst(pattern.count)
                    matched = true
                    break
                }
            }

            if !matched {
                if remaining.first == "'" {
                    let afterQuote = remaining.dropFirst()
                    if let endIdx = afterQuote.firstIndex(of: "'") {
                        let literal = String(remaining[remaining.startIndex...endIdx])
                        remaining = afterQuote[afterQuote.index(after: endIdx)...]
                        result.append(FormatToken(kind: .customLiteral(literal)))
                    } else {
                        result.append(FormatToken(kind: .customLiteral(String(remaining))))
                        remaining = remaining[remaining.endIndex...]
                    }
                } else {
                    result.append(FormatToken(kind: .customLiteral(String(remaining.prefix(1)))))
                    remaining = remaining.dropFirst()
                }
            }
        }

        return result
    }

    /// Live-formatted preview of this single token for a given date.
    func preview(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Locale.preferredLanguages[0])
        formatter.dateFormat = kind.icuPattern
        return formatter.string(from: date)
    }
}
