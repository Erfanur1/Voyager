import SwiftUI
import CoreData
import PhotosUI

struct AddTripView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseService: FirebaseService
    
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var notes = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var coverImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $name)
                    TextField("Destination", text: $destination)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Cover Photo") {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let coverImage = coverImage {
                            Image(uiImage: coverImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            Label("Select Photo", systemImage: "photo")
                        }
                    }
                    .onChange(of: selectedImage) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                coverImage = image
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                // Cloud sync status
                if firebaseService.isSignedIn {
                    Section {
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.blue)
                            Text("Will sync to cloud after saving")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveTrip()
                        }
                    }
                    .disabled(name.isEmpty || destination.isEmpty)
                }
            }
        }
    }
    
    private func saveTrip() async {
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.name = name
        trip.destination = destination
        trip.startDate = startDate
        trip.endDate = endDate
        trip.notes = notes.isEmpty ? "" : notes
        trip.itinerary = ""
        trip.isFavorite = false
        trip.isCompleted = false
        trip.createdAt = Date()
        trip.updatedAt = Date()
        
        if let coverImage = coverImage,
           let imageData = coverImage.jpegData(compressionQuality: 0.8) {
            trip.coverImageData = imageData
        }
        
        do {
            try PersistenceController.shared.save()
            
            // Auto-sync to cloud if signed in
            if firebaseService.isSignedIn {
                try await firebaseService.syncTrip(trip)
                print("✅ Trip auto-synced to cloud")
            }
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Error saving trip: \(error)")
        }
    }
}
