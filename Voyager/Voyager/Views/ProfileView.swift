import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("preferredCurrency") private var preferredCurrency = "USD"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)],
        animation: .default)
    private var trips: FetchedResults<Trip>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)],
        animation: .default)
    private var expenses: FetchedResults<Expense>
    
    let currencies = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "CNY", "INR", "MXN", "SGD", "NZD"]
    
    var totalTrips: Int {
        trips.count
    }
    
    var completedTrips: Int {
        trips.filter { $0.isCompleted }.count
    }
    
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List {
                    // Profile Header
                    Section {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Text(userName.isEmpty ? "?" : String(userName.prefix(1).uppercased()))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(userName.isEmpty ? "Traveler" : userName)
                                    .font(.title2)
                                    .bold()
                                
                                Text("Voyager Explorer")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .listRowBackground(
                            LinearGradient(
                                colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    
                    // Colorful Stats
                    Section("Travel Statistics") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MiniStatCard(
                                icon: "airplane.departure",
                                value: "\(totalTrips)",
                                label: "Trips",
                                gradientColors: [.blue, .cyan]
                            )
                            
                            MiniStatCard(
                                icon: "checkmark.circle.fill",
                                value: "\(completedTrips)",
                                label: "Completed",
                                gradientColors: [.green, .mint]
                            )
                            
                            MiniStatCard(
                                icon: "dollarsign.circle.fill",
                                value: String(format: "%.0f", totalExpenses),
                                label: "Spent",
                                gradientColors: [.orange, .yellow]
                            )
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                    
                    // Settings
                    Section("Settings") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Name")
                            
                            Spacer()
                            
                            TextField("Your name", text: $userName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                        .listRowBackground(Color(.secondarySystemBackground).opacity(0.5))
                        
                        Picker(selection: $preferredCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                HStack {
                                    Text(currency)
                                    Text(currencySymbol(for: currency))
                                        .foregroundColor(.secondary)
                                }
                                .tag(currency)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Preferred Currency")
                            }
                        }
                        .listRowBackground(Color(.secondarySystemBackground).opacity(0.5))
                    }
                    
                    // About
                    Section("About Voyager") {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        .listRowBackground(Color(.secondarySystemBackground).opacity(0.5))
                        
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Build")
                            Spacer()
                            Text("1")
                                .foregroundColor(.secondary)
                        }
                        .listRowBackground(Color(.secondarySystemBackground).opacity(0.5))
                        
                        NavigationLink {
                            ColorfulFeatureList()
                        } label: {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Features")
                            }
                        }
                        .listRowBackground(Color(.secondarySystemBackground).opacity(0.5))
                    }
                    
                    // Privacy
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("All data is stored securely on your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .listRowBackground(Color.clear)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Weather & country data from external APIs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Privacy & Data")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
        }
    }
    
    private func currencySymbol(for code: String) -> String {
        let locale = Locale.availableIdentifiers.compactMap { Locale(identifier: $0) }
            .first { $0.currency?.identifier == code }
        return locale?.currencySymbol ?? code
    }
}

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .bold()
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: gradientColors.map { $0.opacity(0.1) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: gradientColors[0].opacity(0.2), radius: 5, x: 0, y: 3)
    }
}

struct ColorfulFeatureList: View {
    let features = [
        Feature(icon: "airplane", title: "Trip Planning", description: "Organize your travels with detailed trip information", color: [.blue, .cyan]),
        Feature(icon: "dollarsign.circle", title: "Expense Tracking", description: "Track expenses with currency conversion", color: [.green, .mint]),
        Feature(icon: "cloud.sun", title: "Weather Forecasts", description: "Real-time weather for your destinations", color: [.orange, .yellow]),
        Feature(icon: "map", title: "Maps Integration", description: "View trip locations with interactive maps", color: [.red, .pink]),
        Feature(icon: "flag", title: "Country Info", description: "Learn about your destinations", color: [.purple, .pink]),
        Feature(icon: "lock.shield", title: "Local Storage", description: "All data stored securely on your device", color: [.indigo, .blue])
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List(features) { feature in
                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: feature.color.map { $0.opacity(0.2) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: feature.icon)
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: feature.color,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(feature.title)
                            .font(.headline)
                        
                        Text(feature.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(
                    feature.color[0].opacity(0.05)
                )
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Features")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: [Color]
}
