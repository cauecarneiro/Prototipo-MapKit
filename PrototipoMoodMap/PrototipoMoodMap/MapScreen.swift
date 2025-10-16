import SwiftUI
import MapKit

struct MapScreen: View {
    @EnvironmentObject var app: AppState
    @State private var showSheet = false
    @State private var hasSelectedLocation = false
    @State private var infoMessage: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -15.793, longitude: -47.882),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region, annotationItems: annotations()) { item in
                MapAnnotation(coordinate: item.coord) {
                    PinBadge(count: item.count)
                }
            }
                .ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 12) {
                Button {
                    // Garante tentativa de obter localização
                    app.ensureLocationUpdates()

                    if let c = app.location?.coordinate ?? app.locationManager.location?.coordinate {
                        withAnimation { region.center = c }
                        hasSelectedLocation = true
                        infoMessage = nil
                    } else {
                        infoMessage = "Não foi possível obter sua localização. Verifique as permissões."
                    }
                } label: {
                    Label("Minha localização", systemImage: "location.fill")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                if hasSelectedLocation {
                    Button {
                        showSheet = true
                    } label: {
                        Label("Avaliar aqui", systemImage: "plus.bubble.fill")
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
            .padding(20)

            if let msg = infoMessage {
                Text(msg)
                    .font(.footnote)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 100)
                    .transition(.opacity)
            }
        }
        .onChange(of: app.location) { oldValue, newValue in
            if let c = newValue?.coordinate { region.center = c }
        }
        .sheet(isPresented: $showSheet) {
            EvaluationSheet(coord: region.center, dismiss: { showSheet = false })
                .environmentObject(app)
                .presentationDetents([.height(370), .medium])
                .onDisappear { hasSelectedLocation = false }
        }
    }

    private func annotations() -> [Annotation] {
        let count = app.reports.count(near: region.center)
        guard hasSelectedLocation || count > 0 else { return [] }
        return [Annotation(coord: region.center, count: count)]
    }
}

private struct Annotation: Identifiable {
    let id = UUID()
    let coord: CLLocationCoordinate2D
    let count: Int
}

private struct PinBadge: View {
    let count: Int
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "mappin.circle.fill").font(.title).foregroundStyle(.red)
            if count > 0 {
                Text("\(count)")
                    .font(.caption2).padding(4)
                    .background(Circle().fill(.blue))
                    .foregroundStyle(.white)
                    .offset(x: 8, y: -8)
            }
        }
    }
}
