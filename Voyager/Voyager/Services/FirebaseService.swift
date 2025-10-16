import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    @Published var isSignedIn = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private init() {
        // Check if user is already signed in
        if Auth.auth().currentUser != nil {
            isSignedIn = true
        }
    }
    
    // MARK: - Authentication
    
    func signInAnonymously() async throws {
        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                self.isSignedIn = true
            }
            print("✅ Signed in anonymously: \(result.user.uid)")
        } catch {
            print("⚠️ Sign in error: \(error)")
            throw NetworkError.invalidResponse
        }
    }
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Sync Trip to Cloud
    
    func syncTrip(_ trip: Trip) async throws {
        guard let userId = currentUserId else {
            throw NetworkError.invalidResponse
        }
        
        guard let tripId = trip.id?.uuidString else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        do {
            let tripData: [String: Any] = [
                "name": trip.name ?? "",
                "destination": trip.destination ?? "",
                "startDate": Timestamp(date: trip.startDate ?? Date()),
                "endDate": Timestamp(date: trip.endDate ?? Date()),
                "notes": trip.notes ?? "",
                "itinerary": trip.itinerary ?? "",
                "isFavorite": trip.isFavorite,
                "isCompleted": trip.isCompleted,
                "createdAt": Timestamp(date: trip.createdAt ?? Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            try await db.collection("users").document(userId)
                .collection("trips").document(tripId)
                .setData(tripData, merge: true)
            
            // Sync expenses for this trip
            for expense in trip.expensesArray {
                try await syncExpense(expense, userId: userId)
            }
            
            await MainActor.run {
                self.isSyncing = false
                self.lastSyncDate = Date()
            }
            
            print("✅ Trip synced: \(trip.name ?? "")")
        } catch {
            await MainActor.run {
                self.isSyncing = false
            }
            print("⚠️ Sync error: \(error)")
            throw NetworkError.serverError(statusCode: 500)
        }
    }
    
    // MARK: - Sync Expense to Cloud
    
    private func syncExpense(_ expense: Expense, userId: String) async throws {
        guard let expenseId = expense.id?.uuidString,
              let tripId = expense.trip?.id?.uuidString else { return }
        
        let expenseData: [String: Any] = [
            "title": expense.title ?? "",
            "amount": expense.amount,
            "currency": expense.currency ?? "USD",
            "category": expense.category ?? "Other",
            "date": Timestamp(date: expense.date ?? Date()),
            "notes": expense.notes ?? "",
            "tripId": tripId
        ]
        
        try await db.collection("users").document(userId)
            .collection("expenses").document(expenseId)
            .setData(expenseData, merge: true)
    }
    
    // MARK: - Sync All Trips
    
    func syncAllTrips(_ trips: [Trip]) async throws {
        await MainActor.run {
            self.isSyncing = true
        }
        
        for trip in trips {
            try await syncTrip(trip)
        }
        
        await MainActor.run {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
        
        print("✅ All trips synced")
    }
    
    // MARK: - Fetch Trips from Cloud
    
    func fetchTrips() async throws -> [TripDTO] {
        guard let userId = currentUserId else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("trips").getDocuments()
            
            var trips: [TripDTO] = []
            for document in snapshot.documents {
                if let trip = try? document.data(as: TripDTO.self) {
                    trips.append(trip)
                }
            }
            
            print("✅ Fetched \(trips.count) trips from cloud")
            return trips
        } catch {
            print("⚠️ Fetch error: \(error)")
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - Delete Trip from Cloud
    
    func deleteTrip(_ tripId: String) async throws {
        guard let userId = currentUserId else { return }
        
        do {
            // Delete trip
            try await db.collection("users").document(userId)
                .collection("trips").document(tripId).delete()
            
            // Delete associated expenses
            let expensesSnapshot = try await db.collection("users").document(userId)
                .collection("expenses")
                .whereField("tripId", isEqualTo: tripId)
                .getDocuments()
            
            for doc in expensesSnapshot.documents {
                try await doc.reference.delete()
            }
            
            print("✅ Trip deleted from cloud")
        } catch {
            print("⚠️ Delete error: \(error)")
        }
    }
}

// MARK: - Data Transfer Objects

struct TripDTO: Codable {
    let name: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let notes: String?
    let itinerary: String?
    let isFavorite: Bool
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, destination, startDate, endDate, notes, itinerary, isFavorite, isCompleted
    }
}

struct ExpenseDTO: Codable {
    let title: String
    let amount: Double
    let currency: String
    let category: String
    let date: Date
    let notes: String?
    let tripId: String
}
