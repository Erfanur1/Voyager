import SwiftUI

struct EditItineraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var trip: Trip
    @State private var itinerary: String
    
    init(trip: Trip) {
        self.trip = trip
        _itinerary = State(initialValue: trip.itinerary ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $itinerary)
                    .padding()
                Text("Add your day-by-day itinerary")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .navigationTitle("Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        trip.itinerary = itinerary.isEmpty ? nil : itinerary
                        trip.updatedAt = Date()
                        do {
                            try PersistenceController.shared.save()
                            dismiss()
                        } catch {
                            print("Error saving itinerary: \(error)")
                        }
                    }
                }
            }
        }
    }
}
