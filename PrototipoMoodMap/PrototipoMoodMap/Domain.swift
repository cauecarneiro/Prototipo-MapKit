import Foundation
import CoreLocation
import Combine

enum VibeTag: String, CaseIterable, Identifiable {
    case chato, legal, animado, tranquilo, perigoso
    var id: String { rawValue }
}

struct Report: Identifiable {
    let id = UUID()
    let userId: String
    let coord: CLLocationCoordinate2D
    let tags: [VibeTag]
    let text: String?
    let timestamp: Date
}

final class ReportStore: ObservableObject {
    @Published private(set) var items: [Report] = []
    func add(_ r: Report) { items.append(r) }

    // Contagem aproximada por coordenada (arredonda ~11m em lat/lon)
    func count(near coord: CLLocationCoordinate2D) -> Int {
        let key = Self.key(for: coord)
        return items.filter { Self.key(for: $0.coord) == key }.count
    }

    private static func key(for c: CLLocationCoordinate2D) -> String {
        func round6(_ v: Double) -> Double { (v * 1_0000).rounded() / 1_0000 }
        return "\(round6(c.latitude))|\(round6(c.longitude))"
    }
}

final class RateLimiter {
    private let interval: TimeInterval
    private var lastByUser: [String: Date] = [:]
    init(interval: TimeInterval) { self.interval = interval }

    func canSend(userId: String) -> Bool {
        guard let last = lastByUser[userId] else { return true }
        return Date().timeIntervalSince(last) >= interval
    }
    func mark(userId: String) { lastByUser[userId] = Date() }
}


