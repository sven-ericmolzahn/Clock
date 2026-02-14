import CoreLocation
import MapKit
import SwiftUI

@Observable
final class MapTimeZonePickerViewModel {
    var selectedCoordinate: CLLocationCoordinate2D?
    var isGeocoding = false
    var geocodedCityName: String?
    var geocodedTimeZone: TimeZone?
    var errorMessage: String?
    var editableLabel = ""
    var geocodedCountryCode: String?
    var cameraPosition: MapCameraPosition = .automatic

    // Search
    var searchQuery = ""
    var searchResults: [MKMapItem] = []
    var isSearching = false

    private var geocodeTask: Task<Void, Never>?
    private var activeRequest: MKReverseGeocodingRequest?
    private var searchTask: Task<Void, Never>?

    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        geocodeTask?.cancel()
        activeRequest?.cancel()
        clearSearch()

        withAnimation(.spring(duration: 0.3)) {
            selectedCoordinate = coordinate
            isGeocoding = true
            geocodedCityName = nil
            geocodedTimeZone = nil
            geocodedCountryCode = nil
            errorMessage = nil
            editableLabel = ""
        }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else {
            withAnimation(.spring(duration: 0.3)) {
                errorMessage = "Invalid location"
                isGeocoding = false
            }
            return
        }
        activeRequest = request

        geocodeTask = Task {
            do {
                let mapItems = try await request.mapItems

                guard !Task.isCancelled else { return }

                guard let item = mapItems.first else {
                    withAnimation(.spring(duration: 0.3)) {
                        self.errorMessage = "No location found"
                        self.isGeocoding = false
                    }
                    return
                }

                let name = item.name ?? "Unknown"
                let country = item.placemark.isoCountryCode
                withAnimation(.spring(duration: 0.3)) {
                    self.geocodedCityName = name
                    self.geocodedTimeZone = item.timeZone
                    self.geocodedCountryCode = country
                    self.editableLabel = name
                    self.isGeocoding = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.3)) {
                    self.errorMessage = error.localizedDescription
                    self.isGeocoding = false
                }
            }
        }
    }

    // MARK: - Search

    func performSearch() {
        searchTask?.cancel()
        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation(.spring(duration: 0.3)) {
                searchResults = []
                isSearching = false
            }
            return
        }

        isSearching = true

        searchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.3)) {
                    self.searchResults = response.mapItems
                    self.isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.3)) {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }

    func selectSearchResult(_ item: MKMapItem) {
        clearSearch()

        let coordinate = item.location.coordinate
        let name = item.name ?? item.address?.shortAddress ?? "Unknown"
        let country = item.placemark.isoCountryCode

        withAnimation(.spring(duration: 0.3)) {
            selectedCoordinate = coordinate
            geocodedCityName = name
            geocodedTimeZone = item.timeZone
            geocodedCountryCode = country
            editableLabel = name
            isGeocoding = false
            errorMessage = nil
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
            ))
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        isSearching = false
    }

    func reset() {
        geocodeTask?.cancel()
        activeRequest?.cancel()
        clearSearch()
        withAnimation(.spring(duration: 0.3)) {
            selectedCoordinate = nil
            isGeocoding = false
            geocodedCityName = nil
            geocodedTimeZone = nil
            geocodedCountryCode = nil
            errorMessage = nil
            editableLabel = ""
        }
    }
}
