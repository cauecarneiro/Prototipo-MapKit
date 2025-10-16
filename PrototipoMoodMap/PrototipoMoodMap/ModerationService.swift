import Foundation

struct ModerationResult {
    let allowed: Bool
    let reason: String?
    let normalizedText: String?
}

final class ModerationService {
    // Substitua por Foundation Model quando desejar
    private let toxicLexicon: [String] = ["idiota","burro","lixo","odiar","xingar"]
    private let slang: [String:String] = ["top":"legal","massa":"legal","bomba":"animado"]

    func moderate(_ text: String?) async -> ModerationResult {
        guard let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else {
            return ModerationResult(allowed: true, reason: nil, normalizedText: nil)
        }
        let lower = t.lowercased()
        if toxicLexicon.contains(where: { lower.contains($0) }) {
            return ModerationResult(allowed: false, reason: "Texto com linguagem inadequada.", normalizedText: nil)
        }
        var normalized = lower
        slang.forEach { k, v in normalized = normalized.replacingOccurrences(of: k, with: v) }
        return ModerationResult(allowed: true, reason: nil, normalizedText: normalized)
    }
}
