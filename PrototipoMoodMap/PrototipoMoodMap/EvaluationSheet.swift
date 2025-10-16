import SwiftUI
import CoreLocation

struct EvaluationSheet: View {
    @EnvironmentObject var app: AppState
    let coord: CLLocationCoordinate2D
    let dismiss: () -> Void

    @State private var selected: Set<VibeTag> = [.legal]
    @State private var text: String = ""
    @State private var sending = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Como está o local?") {
                    FlowLayout {
                        ForEach(VibeTag.allCases) { tag in
                            Chip(title: tag.rawValue.capitalized, isOn: selected.contains(tag)) {
                                if selected.contains(tag) {
                                    selected.remove(tag)
                                } else {
                                    selected.insert(tag)
                                }
                            }
                        }
                    }
                }
                Section("Conte mais (opcional)") {
                    TextEditor(text: $text)
                        .frame(minHeight: 90)
                    HStack {
                        Spacer()
                        Text("\(text.count)/140").foregroundStyle(.secondary)
                    }
                }
                if let e = errorMsg {
                    Text(e).foregroundStyle(.red)
                }
                Button {
                    Task { await send() }
                } label: {
                    sending ? AnyView(ProgressView()) : AnyView(Text("Enviar"))
                }
                .disabled(sending)
            }
            .navigationTitle("Avaliar aqui")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar", action: dismiss) }
            }
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > 140 { text = String(newValue.prefix(140)) }
            }
        }
    }

    private func send() async {
        errorMsg = nil
        let uid = deviceId()
        guard app.rateLimiter.canSend(userId: uid) else {
            errorMsg = "Aguarde alguns minutos antes de enviar outra avaliação."
            return
        }
        sending = true
        defer { sending = false }

        let mod = await app.moderation.moderate(text)
        guard mod.allowed else {
            errorMsg = mod.reason ?? "Conteúdo não permitido."
            return
        }
        let finalText = mod.normalizedText ?? (text.isEmpty ? nil : text)

        let report = Report(
            userId: uid,
            coord: coord,
            tags: Array(selected).sorted { $0.rawValue < $1.rawValue },
            text: finalText,
            timestamp: Date()
        )
        app.reports.add(report)
        app.rateLimiter.mark(userId: uid)

        await app.notifications.announce(report: report) // simula broadcast
        dismiss()
    }

    private func deviceId() -> String {
        if let id = UserDefaults.standard.string(forKey: "device_id") { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "device_id")
        return id
    }
}

struct Chip: View {
    let title: String
    var isOn: Bool
    var action: () -> Void
    var body: some View {
        Button(title) { action() }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isOn ? .blue.opacity(0.2) : .gray.opacity(0.12), in: Capsule())
    }
}

struct FlowLayout<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
