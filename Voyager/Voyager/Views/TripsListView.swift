import SwiftUI
import CoreData

struct TripsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseService: FirebaseService
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Trip.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)
        ],
        animation: .default)
    private var trips: FetchedResults<Trip>
    
    @State private var showingAddTrip = false
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var error: Error?
    
    // FILTER ENUM - MUST BE INSIDE THE STRUCT
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case completed = "Completed"
        case favorites = "Favorites"
    }
    
    var filteredTrips: [Trip] {
        var result = Array(trips)
        
        switch filterOption {
        case .all:
            break
        case .upcoming:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        case .favorites:
            result = result.filter { $0.isFavorite }
        }
        
        if !searchText.isEmpty {
            result = result.filter { trip in
                (trip.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                (trip.destination ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if filteredTrips.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredTrips, id: \.self) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    ColorfulTripCard(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Trips")
            .searchable(text: $searchText, prompt: "Search trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter", selection: $filterOption) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Label(option.rawValue, systemImage: iconForFilter(option))
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        SyncStatusView()
                        
                        Button {
                            showingAddTrip = true
                        } label: {
                            Label("Add Trip", systemImage: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView()
            }
            .errorAlert(error: $error)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: searchText.isEmpty ? "airplane.departure" : "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Trips Yet" : "No Results")
                    .font(.title2)
                    .bold()
                
                Text(searchText.isEmpty ? "Start planning your next adventure!" : "Try a different search term")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button {
                    showingAddTrip = true
                } label: {
                    Label("Add Your First Trip", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding()
    }
    
    // HELPER FUNCTION - MUST BE INSIDE THE STRUCT
    private func iconForFilter(_ option: FilterOption) -> String {
        switch option {
        case .all: return "list.bullet"
        case .upcoming: return "clock"
        case .completed: return "checkmark.circle"
        case .favorites: return "star.fill"
        }
    }
}

struct ColorfulTripCard: View {
    @ObservedObject var trip: Trip
    
    var cardGradient: [Color] {
        if trip.isCompleted {
            return [.green.opacity(0.6), .teal.opacity(0.6)]
        } else if trip.isFavorite {
            return [.orange.opacity(0.7), .pink.opacity(0.7)]
        } else {
            return [.blue.opacity(0.7), .purple.opacity(0.7)]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover Image or Gradient
            ZStack(alignment: .topTrailing) {
                if let imageData = trip.coverImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    LinearGradient(
                        colors: cardGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 10)
                            
                            Text(trip.destination ?? "")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                    }
                }
                
                // Badges
                HStack(spacing: 8) {
                    if trip.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    if trip.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding(12)
            }
            .frame(height: 200)
            
            // Trip Info
            VStack(alignment: .leading, spacing: 14) {
                // Title and Destination
                VStack(alignment: .leading, spacing: 6) {
                    Text(trip.name ?? "Untitled")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(trip.destination ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Date and Stats
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(trip.dateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("\(trip.durationInDays)d")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(String(format: "$%.0f", trip.totalExpenses))
                                .font(.caption)
                                .bold()
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Mini weather widget
                if let destination = trip.destination, !trip.isCompleted {
                    Divider()
                    MiniWeatherView(destination: destination)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
