import Foundation
import UserNotifications
import CoreLocation

final class NotificationService {
    func announce(report: Report) async {
        let content = UNMutableNotificationContent()
        let tags = report.tags.map { $0.rawValue.capitalized }.joined(separator: ", ")
        let titulo = tags.isEmpty ? "Nova avaliação" : "Vibe: \(tags)"
        content.title = titulo
        if let t = report.text, !t.isEmpty {
            content.body = t
        } else {
            content.body = String(format: "lat %.3f, lon %.3f", report.coord.latitude, report.coord.longitude)
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(req)
    }
}
