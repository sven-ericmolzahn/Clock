import MapKit
import SwiftUI

struct MapTimeZonePicker: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = MapTimeZonePickerViewModel()
    @FocusState private var isLabelFocused: Bool

    var body: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition) {
                if let coordinate = viewModel.selectedCoordinate {
                    Annotation("", coordinate: coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                }
            }
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if let coordinate = proxy.convert(value.location, from: .local) {
                            viewModel.handleMapTap(at: coordinate)
                        }
                    }
            )
        }
        .overlay(alignment: .top) {
            searchOverlay
        }
        .overlay {
            hintOverlay
        }
        .overlay {
            geocodingOverlay
        }
        .overlay {
            resultCardOverlay
        }
        .overlay {
            errorCardOverlay
        }
    }

    // MARK: - Search

    @ViewBuilder
    private var searchOverlay: some View {
        if viewModel.geocodedTimeZone == nil && !viewModel.isGeocoding && viewModel.errorMessage == nil {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search city or place...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit { viewModel.performSearch() }
                    if viewModel.isSearching {
                        ProgressView()
                            .controlSize(.small)
                    } else if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                if !viewModel.searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.searchResults, id: \.self) { item in
                                Button {
                                    viewModel.selectSearchResult(item)
                                } label: {
                                    searchResultRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 4)
                }
            }
            .padding(8)
            .transition(.opacity)
        }
    }

    private func searchResultRow(_ item: MKMapItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name ?? "Unknown")
                    .font(.callout)
                    .fontWeight(.medium)
                if let subtitle = searchSubtitle(for: item) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let tz = item.timeZone {
                Text(tz.abbreviation() ?? "")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func searchSubtitle(for item: MKMapItem) -> String? {
        guard let short = item.address?.shortAddress, short != item.name else { return nil }
        return short
    }

    // MARK: - Hint

    @ViewBuilder
    private var hintOverlay: some View {
        if !viewModel.isGeocoding && viewModel.geocodedTimeZone == nil && viewModel.errorMessage == nil && viewModel.selectedCoordinate == nil && viewModel.searchResults.isEmpty {
            VStack {
                Spacer()
                Text("Click the map or search for a city")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 12)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Geocoding spinner

    @ViewBuilder
    private var geocodingOverlay: some View {
        if viewModel.isGeocoding {
            Color.black.opacity(0.2)
                .onTapGesture { viewModel.reset() }

            VStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Looking up location...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Result card

    @ViewBuilder
    private var resultCardOverlay: some View {
        if let tz = viewModel.geocodedTimeZone, viewModel.errorMessage == nil {
            Color.black.opacity(0.2)
                .onTapGesture { viewModel.reset() }

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.red)
                    Text("New Clock")
                        .font(.headline)
                    Spacer()
                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }

                TextField("Label", text: $viewModel.editableLabel)
                    .textFieldStyle(.roundedBorder)
                    .focused($isLabelFocused)

                Text(tz.identifier)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Add Clock") {
                    let label = viewModel.editableLabel.isEmpty
                        ? (viewModel.geocodedCityName ?? tz.identifier)
                        : viewModel.editableLabel
                    appState.addWorldClock(label: label, timeZoneIdentifier: tz.identifier, countryCode: viewModel.geocodedCountryCode)
                    viewModel.reset()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .frame(width: 260)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .transition(.scale.combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .milliseconds(300))
                isLabelFocused = true
            }
        }
    }

    // MARK: - Error card

    @ViewBuilder
    private var errorCardOverlay: some View {
        if let error = viewModel.errorMessage {
            Color.black.opacity(0.2)
                .onTapGesture { viewModel.reset() }

            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                Button("Dismiss") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .frame(width: 260)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .transition(.scale.combined(with: .opacity))
        }
    }
}
