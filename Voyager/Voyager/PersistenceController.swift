import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Voyager")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, handle this more gracefully
                print("⚠️ Core Data failed to load: \(error.localizedDescription)")
                fatalError("Failed to load Core Data: \(error)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
            print("✅ Data saved successfully")
        } catch {
            print("⚠️ Error saving context: \(error.localizedDescription)")
            
            // Rollback changes on error
            context.rollback()
            throw DataError.saveFailed
        }
    }
    
    func delete(_ object: NSManagedObject) throws {
        let context = container.viewContext
        context.delete(object)
        
        do {
            try context.save()
            print("✅ Object deleted successfully")
        } catch {
            print("⚠️ Error deleting object: \(error.localizedDescription)")
            context.rollback()
            throw DataError.deleteFailed
        }
    }
    
    // Helper for preview/testing
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data
        let trip = Trip(context: context)
        trip.id = UUID()
        trip.name = "Summer Vacation"
        trip.destination = "Paris, France"
        trip.startDate = Date()
        trip.endDate = Date().addingTimeInterval(7 * 24 * 3600)
        trip.notes = "Visit the Eiffel Tower!"
        trip.isFavorite = true
        trip.isCompleted = false
        trip.createdAt = Date()
        trip.updatedAt = Date()
        
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.title = "Hotel"
        expense.amount = 500
        expense.category = "Accommodation"
        expense.date = Date()
        expense.currency = "EUR"
        expense.trip = trip
        
        try? context.save()
        return controller
    }()
}

// MARK: - Trip Extensions
extension Trip {
    var expensesArray: [Expense] {
        let set = expenses as? Set<Expense> ?? []
        return set.sorted { $0.date ?? Date() > $1.date ?? Date() }
    }
    
    var totalExpenses: Double {
        expensesArray.reduce(0) { $0 + $1.amount }
    }
    
    var durationInDays: Int {
        guard let start = startDate, let end = endDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days, 1) // At least 1 day
    }
    
    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        guard let start = startDate, let end = endDate else { return "" }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var isUpcoming: Bool {
        guard let startDate = startDate else { return false }
        return startDate > Date() && !isCompleted
    }
    
    var isPast: Bool {
        guard let endDate = endDate else { return false }
        return endDate < Date() || isCompleted
    }
}
