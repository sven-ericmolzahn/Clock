import SwiftUI

struct MenuBarPanel: View {
    @Environment(AppState.self) private var appState
    @State private var converterInput = ""
    @FocusState private var isConverterFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            LocalClockView()

            if !appState.worldClocks.isEmpty {
                converterField

                Divider()

                ForEach(appState.worldClocks) { clock in
                    WorldClockRow(clock: clock, overrideDate: converterDate)
                }
            }

            Divider()

            HStack {
                SettingsLink {
                    Text("Settings...")
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Converter

    private var converterField: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right.arrow.left.circle")
                .foregroundStyle(converterDate != nil ? Color.accentColor : Color.secondary)
            TextField("Convert a time (e.g. 15:00)", text: $converterInput)
                .textFieldStyle(.plain)
                .focused($isConverterFocused)
            if !converterInput.isEmpty {
                if converterDate == nil {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Button {
                    converterInput = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private var converterDate: Date? {
        let trimmed = converterInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Self.parseTime(trimmed, relativeTo: appState.currentDate)
    }

    /// Parses a time string into a Date on the same calendar day as `reference`, in the local timezone.
    static func parseTime(_ input: String, relativeTo reference: Date) -> Date? {
        let calendar = Calendar.current

        // Try common time formats
        let formats = ["HH:mm", "H:mm", "HH.mm", "H.mm", "h:mm a", "h:mma", "h a", "ha", "HHmm", "HH"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.defaultDate = reference

        for format in formats {
            formatter.dateFormat = format
            if let parsed = formatter.date(from: input) {
                let components = calendar.dateComponents([.hour, .minute], from: parsed)
                guard let hour = components.hour, let minute = components.minute else { continue }
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: reference)
            }
        }

        // Try bare number as hour (e.g. "9" → 09:00, "15" → 15:00)
        if let hour = Int(input), (0...23).contains(hour) {
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: reference)
        }

        return nil
    }
}
