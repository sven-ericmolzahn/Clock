import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppState.self) private var appState

    private static let menuBarExamples: [(label: String, format: String)] = [
        ("Time", "HH:mm"),
        ("12-hour", "h:mm a"),
        ("Seconds", "HH:mm:ss"),
        ("Weekday", "EEE HH:mm"),
        ("Cal week", "'W'w · EEE HH:mm"),
        ("Date", "dd MMM HH:mm"),
        ("ISO date", "yyyy-MM-dd HH:mm"),
        ("Full", "EEEE, d MMMM"),
    ]

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section("Menu Bar Format") {
                TextField("Date format pattern", text: $appState.menuBarFormat)
                Text("Preview: \(menuBarPreview)")
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(Self.menuBarExamples, id: \.format) { example in
                        Button {
                            appState.menuBarFormat = example.format
                        } label: {
                            Text(example.label)
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(appState.menuBarFormat == example.format ? .accentColor : nil)
                    }
                }
            }

            Section("World Clock Format") {
                TextField("Date format pattern", text: $appState.worldClockFormat)
                Text("Preview: \(worldClockPreview)")
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("Use Unicode date format patterns (e.g. HH:mm, yyyy-MM-dd, 'W'w for week)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var menuBarPreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = appState.menuBarFormat
        return formatter.string(from: appState.currentDate)
    }

    private var worldClockPreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = appState.worldClockFormat
        return formatter.string(from: appState.currentDate)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (i > 0 ? spacing : 0)
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            if i > 0 { y += spacing }
            var x = bounds.minX
            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if !rows[rows.count - 1].isEmpty && currentWidth + spacing + size.width > maxWidth {
                rows.append([index])
                currentWidth = size.width
            } else {
                if !rows[rows.count - 1].isEmpty { currentWidth += spacing }
                rows[rows.count - 1].append(index)
                currentWidth += size.width
            }
        }
        return rows
    }
}
