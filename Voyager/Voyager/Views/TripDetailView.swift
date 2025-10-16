import SwiftUI
import CoreData

struct TripDetailView: View {
    @ObservedObject var trip: Trip
    @State private var selectedTab = 0
    @State private var showingEdit = false
    
    var body: some View {
        VStack(spacing: 0) {
            TripHeaderView(trip: trip)
            
            // Colorful Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Weather").tag(1)
                Text("Map").tag(2)
                Text("Plans").tag(3)
                Text("💰").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            TabView(selection: $selectedTab) {
                ColorfulTripOverview(trip: trip)
                    .tag(0)
                TripWeatherInfoView(trip: trip)
                    .tag(1)
                TripMapView(trip: trip)
                    .tag(2)
                TripItineraryView(trip: trip)
                    .tag(3)
                TripExpensesView(trip: trip)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditTripView(trip: trip)
        }
    }
}

struct TripHeaderView: View {
    @ObservedObject var trip: Trip
    
    var headerGradient: [Color] {
        if trip.isCompleted {
            return [.green, .teal]
        } else {
            return [.blue, .purple]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let imageData = trip.coverImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                ZStack {
                    LinearGradient(
                        colors: headerGradient.map { $0.opacity(0.8) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                        
                        Text(trip.destination ?? "")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                }
                .frame(height: 220)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.name ?? "Untitled")
                            .font(.title2)
                            .bold()
                        
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
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button {
                            trip.isFavorite.toggle()
                            do {
                                try PersistenceController.shared.save()
                            } catch {
                                print("Error toggling favorite: \(error)")
                            }
                        } label: {
                            Image(systemName: trip.isFavorite ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(trip.isFavorite ? .yellow : .gray)
                        }
                        
                        if trip.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(trip.dateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(trip.durationInDays) days")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct ColorfulTripOverview: View {
    @ObservedObject var trip: Trip
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Colorful Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ColorfulStatCard(
                        icon: "calendar",
                        title: "Duration",
                        value: "\(trip.durationInDays)",
                        unit: "days",
                        gradientColors: [.blue, .cyan]
                    )
                    
                    ColorfulStatCard(
                        icon: "dollarsign.circle.fill",
                        title: "Total Spent",
                        value: String(format: "%.0f", trip.totalExpenses),
                        unit: "USD",
                        gradientColors: [.green, .mint]
                    )
                    
                    ColorfulStatCard(
                        icon: "list.bullet.rectangle.fill",
                        title: "Expenses",
                        value: "\(trip.expensesArray.count)",
                        unit: "items",
                        gradientColors: [.orange, .yellow]
                    )
                    
                    ColorfulStatCard(
                        icon: trip.isCompleted ? "checkmark.circle.fill" : "clock.fill",
                        title: "Status",
                        value: trip.isCompleted ? "Done" : "Upcoming",
                        unit: "",
                        gradientColors: trip.isCompleted ? [.green, .teal] : [.purple, .pink]
                    )
                }
                .padding(.horizontal)
                
                // Notes Section
                if let notes = trip.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Notes")
                                .font(.headline)
                        }
                        
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [.orange.opacity(0.1), .red.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
                
                // Mini Map Preview
                if let destination = trip.destination {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Location")
                                .font(.headline)
                        }
                        
                        MiniMapView(destination: destination)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.red.opacity(0.3), .pink.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct ColorfulStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .bold()
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                LinearGradient(
                    colors: gradientColors.map { $0.opacity(0.1) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .cornerRadius(20)
        .shadow(color: gradientColors[0].opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct TripWeatherInfoView: View {
    @ObservedObject var trip: Trip
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let destination = trip.destination {
                    WeatherView(destination: destination)
                        .padding(.horizontal)
                    
                    CountryInfoView(destination: destination)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct TripItineraryView: View {
    @ObservedObject var trip: Trip
    @State private var editingItinerary = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let itinerary = trip.itinerary, !itinerary.isEmpty {
                    Text(itinerary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "list.bullet.clipboard.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Itinerary Yet")
                                .font(.title2)
                                .bold()
                            
                            Text("Add a day-by-day plan for your trip")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Add Itinerary") {
                            editingItinerary = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(trip.itinerary == nil ? "Add" : "Edit") {
                    editingItinerary = true
                }
            }
        }
        .sheet(isPresented: $editingItinerary) {
            EditItineraryView(trip: trip)
        }
    }
}
