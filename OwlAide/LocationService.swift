import Foundation
import Combine
import CoreLocation

/// Location service: Gets the current location for emergency calls.
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Request location permission and get current location.
    func requestCurrentLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        authorizationStatus = status

        // Return nil if denied or restricted.
        if status == .denied || status == .restricted {
            return nil
        }

        // Request permission if not determined.
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Wait for permission callback
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if manager.authorizationStatus != .authorizedWhenInUse && manager.authorizationStatus != .authorizedAlways {
                return nil
            }
        }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    /// Format as a readable coordinate string.
    func formattedLocation() async -> String {
        guard let location = await requestCurrentLocation() else {
            return String(localized: "Failed to get location")
        }
        lastLocation = location
        return "\(String(localized: "Lat")):\(String(format: "%.4f", location.coordinate.latitude)) \(String(localized: "Long")):\(String(format: "%.4f", location.coordinate.longitude))"
    }

    /// Generate emergency SOS text (including location).
    func emergencyMessage() async -> String {
        let locationStr = await formattedLocation()
        let title = String(localized: "🆘 SOS Emergency")
        let locLabel = String(localized: "Location")
        let timeLabel = String(localized: "Time")
        let body = String(localized: "Please contact me ASAP!")

        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)

        return """
        \(title)
        \(locLabel): \(locationStr)
        \(timeLabel): \(timeStr)
        \(body)
        """
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.last)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
