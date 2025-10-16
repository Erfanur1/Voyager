import SwiftUI
import CoreData
import FirebaseCore

@main
struct VoyagerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var firebaseService = FirebaseService.shared
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured")
        
        // Sign in anonymously on launch
        Task {
            do {
                try await FirebaseService.shared.signInAnonymously()
            } catch {
                print("⚠️ Failed to sign in: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(firebaseService)
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
                .tag(0)
            
            AllExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign.circle")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}
