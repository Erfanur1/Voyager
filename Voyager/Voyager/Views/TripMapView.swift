import SwiftUI
import MapKit

struct TripMapView: View {
    @ObservedObject var trip: Trip
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
    @State private var annotations: [MapAnnotation] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                MapMarker(coordinate: annotation.coordinate, tint: .red)
            }
            .ignoresSafeArea()
            
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.destination ?? "Unknown")
                            .font(.headline)
                        Text("Tap to see location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
        .task {
            await loadMapLocation()
        }
        .errorAlert(error: $error)
    }
    
    private func loadMapLocation() async {
        guard let destination = trip.destination else {
            isLoading = false
            return
        }
        
        do {
            let coordinate = try await locationManager.geocodeAddress(destination)
            
            await MainActor.run {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
                
                annotations = [MapAnnotation(
                    id: UUID(),
                    name: destination,
                    coordinate: coordinate
                )]
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
}

struct MapAnnotation: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// Simpler map view for overview
struct MiniMapView: View {
    let destination: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
    @State private var annotations: [MapAnnotation] = []
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: .red)
        }
        .frame(height: 200)
        .cornerRadius(12)
        .task {
            await loadLocation()
        }
    }
    
    private func loadLocation() async {
        let locationManager = LocationManager()
        
        do {
            let coordinate = try await locationManager.geocodeAddress(destination)
            
            await MainActor.run {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
                
                annotations = [MapAnnotation(
                    id: UUID(),
                    name: destination,
                    coordinate: coordinate
                )]
            }
        } catch {
            print("Map error: \(error)")
        }
    }
}
