import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var isUpdatingLocation = false
    private var isUpdatingHeading = false

    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var errorMessage: String?

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = 1
    }

    func requestPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startUpdates() {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdatesIfNeeded()
            startHeadingUpdatesIfNeeded()
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            errorMessage = "Location permission is not granted."
            stopUpdates()
        @unknown default:
            break
        }
    }

    func stopUpdates() {
        if isUpdatingLocation {
            locationManager.stopUpdatingLocation()
            isUpdatingLocation = false
        }

        if isUpdatingHeading {
            locationManager.stopUpdatingHeading()
            isUpdatingHeading = false
        }
    }

    func requestLocation() {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            errorMessage = "Enable location permission in Settings to refresh weather."
        @unknown default:
            break
        }
    }

    private func startLocationUpdatesIfNeeded() {
        guard !isUpdatingLocation else { return }
        locationManager.startUpdatingLocation()
        isUpdatingLocation = true
    }

    private func startHeadingUpdatesIfNeeded() {
        guard CLLocationManager.headingAvailable() else {
            heading = nil
            return
        }
        guard !isUpdatingHeading else { return }
        locationManager.startUpdatingHeading()
        isUpdatingHeading = true
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            errorMessage = nil
            startUpdates()
        case .denied, .restricted:
            errorMessage = "Location permission is not granted."
            stopUpdates()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        errorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == kCLErrorDomain, nsError.code == CLError.locationUnknown.rawValue {
            return
        }
        errorMessage = "Location error: \(error.localizedDescription)"
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        false
    }
}
