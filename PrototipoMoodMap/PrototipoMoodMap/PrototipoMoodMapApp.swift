import SwiftUI
import UserNotifications
import CoreLocation

@main
struct PrototipoMoodMapApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MapScreen()
                .environmentObject(appState)
                .task {
                    await requestPermissions()
                }
        }
    }

    private func requestPermissions() async {
        // Notificações
        let _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        // Localização (delegado está em AppState)
        appState.locationManager.requestWhenInUseAuthorization()
    }
}
