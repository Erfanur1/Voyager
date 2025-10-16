import SwiftUI
import CoreData
import PhotosUI

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseService: FirebaseService
    @ObservedObject var trip: Trip
    
    @State private var name: String
    @State private var destination: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var selectedImage: PhotosPickerItem?
    @State private var coverImage: UIImage?
    
    init(trip: Trip) {
        self.trip = trip
        _name = State(initialValue: trip.name ?? "")
        _destination = State(initialValue: trip.destination ?? "")
        _startDate = State(initialValue: trip.startDate ?? Date())
        _endDate = State(initialValue: trip.endDate ?? Date())
        _notes = State(initialValue: trip.notes ?? "")
        _isCompleted = State(initialValue: trip.isCompleted)
        
        if let imageData = trip.coverImageData,
           let image = UIImage(data: imageData) {
            _coverImage = State(initialValue: image)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $name)
                    TextField("Destination", text: $destination)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    Toggle("Completed", isOn: $isCompleted)
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
                            Text("Changes will sync to cloud")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                }
            }
        }
    }
    
    private func saveChanges() async {
        trip.name = name
        trip.destination = destination
        trip.startDate = startDate
        trip.endDate = endDate
        trip.notes = notes.isEmpty ? "" : notes
        trip.isCompleted = isCompleted
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
                print("✅ Trip changes auto-synced to cloud")
            }
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}
