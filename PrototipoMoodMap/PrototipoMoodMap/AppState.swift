import Foundation
import CoreLocation
import Combine

final class AppState: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    let locationManager = CLLocationManager()
    let moderation = ModerationService()
    let notifications = NotificationService()
    let reports = ReportStore()
    let rateLimiter = RateLimiter(interval: 600) // 10 minutos

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        ensureLocationUpdates()
    }

    // CLLocationManagerDelegate (iOS 14+ moderno)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Log básico para debug local
        print("Location error:", error.localizedDescription)
    }

    // Garante que estamos pedindo permissão e iniciando updates quando possível
    func ensureLocationUpdates() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.startUpdatingLocation()
            }
        }
    }
}
