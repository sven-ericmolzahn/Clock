import SwiftUI
import UniformTypeIdentifiers

struct FormatBuilderView: View {
    @Binding var formatString: String
    let presets: [(label: LocalizedStringResource, format: String)]
    let currentDate: Date

    @State private var tokens: [FormatToken] = []
    @State private var draggingToken: FormatToken?
    @State private var hoveredTokenID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            compositionStrip

            Text("Preview: \(fullPreview)")
                .foregroundStyle(.secondary)

            if !presets.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(presets, id: \.format) { preset in
                        Button {
                            formatString = preset.format
                        } label: {
                            Text(preset.label)
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(formatString == preset.format ? .accentColor : nil)
                    }
                }
            }

            tokenPalette
        }
        .onAppear { tokens = FormatToken.parse(formatString) }
        .onChange(of: formatString) { _, newValue in
            if FormatToken.icuString(from: tokens) != newValue {
                tokens = FormatToken.parse(newValue)
            }
        }
        .onChange(of: tokens) { _, newValue in
            let icu = FormatToken.icuString(from: newValue)
            if icu != formatString {
                formatString = icu
            }
        }
    }

    // MARK: - Composition Strip

    private var compositionStrip: some View {
        Group {
            if tokens.isEmpty {
                Text("Add format components below")
                    .foregroundStyle(.tertiary)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(tokens) { token in
                            compositionPill(token)
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .frame(height: 32)
            }
        }
        .padding(.vertical, 4)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func compositionPill(_ token: FormatToken) -> some View {
        HStack(spacing: 2) {
            Text(token.preview(for: currentDate))
                .font(.system(.callout, design: .monospaced))

            if hoveredTokenID == token.id {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        tokens.removeAll { $0.id == token.id }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 5))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredTokenID = hovering ? token.id : nil
            }
        }
        .onDrag {
            draggingToken = token
            return NSItemProvider(object: token.kind.icuPattern as NSString)
        }
        .onDrop(of: [.text], delegate: TokenReorderDelegate(
            token: token,
            tokens: $tokens,
            draggingToken: $draggingToken
        ))
        .opacity(draggingToken?.id == token.id ? 0.4 : 1)
    }

    // MARK: - Token Palette

    private var tokenPalette: some View {
        VStack(alignment: .leading, spacing: 6) {
            paletteSection(
                title: String(localized: "Time", comment: "Token palette section"),
                kinds: FormatTokenKind.paletteTokens.filter { $0.category == .time }
            )
            paletteSection(
                title: String(localized: "Date", comment: "Token palette section"),
                kinds: FormatTokenKind.paletteTokens.filter { $0.category == .date }
            )
            paletteSection(
                title: String(localized: "Separators"),
                kinds: FormatTokenKind.paletteTokens.filter { $0.category == .separator }
            )
        }
    }

    private func paletteSection(title: String, kinds: [FormatTokenKind]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            FlowLayout(spacing: 4) {
                ForEach(kinds, id: \.self) { kind in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            tokens.append(FormatToken(kind: kind))
                        }
                    } label: {
                        Text(kind.displayLabel)
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
    }

    // MARK: - Preview

    private var fullPreview: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Locale.preferredLanguages[0])
        formatter.dateFormat = FormatToken.icuString(from: tokens)
        return formatter.string(from: currentDate)
    }
}

// MARK: - Drag Reorder Delegate

private struct TokenReorderDelegate: DropDelegate {
    let token: FormatToken
    @Binding var tokens: [FormatToken]
    @Binding var draggingToken: FormatToken?

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingToken,
              dragging.id != token.id,
              let from = tokens.firstIndex(where: { $0.id == dragging.id }),
              let to = tokens.firstIndex(where: { $0.id == token.id })
        else { return }

        withAnimation(.snappy(duration: 0.2)) {
            tokens.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingToken = nil
        return true
    }
}
