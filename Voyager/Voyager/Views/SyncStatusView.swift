import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.updatedAt, ascending: false)]
    ) private var trips: FetchedResults<Trip>
    
    @State private var showingSyncAlert = false
    @State private var syncError: Error?
    
    var body: some View {
        Button {
            Task {
                await syncAllTrips()
            }
        } label: {
            HStack(spacing: 6) {
                if firebaseService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: firebaseService.isSignedIn ? "cloud.fill" : "cloud.slash")
                }
                
                if let lastSync = firebaseService.lastSyncDate {
                    Text(timeAgo(lastSync))
                        .font(.caption2)
                } else if !firebaseService.isSyncing {
                    Text("Sync")
                        .font(.caption2)
                }
            }
            .foregroundColor(firebaseService.isSignedIn ? .blue : .secondary)
        }
        .disabled(firebaseService.isSyncing || !firebaseService.isSignedIn)
        .alert("Sync Complete", isPresented: $showingSyncAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(trips.count) trips synced to cloud")
        }
        .errorAlert(error: $syncError)
    }
    
    private func syncAllTrips() async {
        do {
            try await firebaseService.syncAllTrips(Array(trips))
            await MainActor.run {
                showingSyncAlert = true
            }
        } catch {
            await MainActor.run {
                syncError = error
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h ago"
        } else {
            return "\(seconds / 86400)d ago"
        }
    }
}

// Add this to your TripsListView toolbar
struct SyncInfoBanner: View {
    @EnvironmentObject var firebaseService: FirebaseService
    
    var body: some View {
        if !firebaseService.isSignedIn {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cloud Sync Unavailable")
                        .font(.subheadline)
                        .bold()
                    Text("Data stored locally only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        } else if firebaseService.isSyncing {
            HStack(spacing: 12) {
                ProgressView()
                
                Text("Syncing to cloud...")
                    .font(.subheadline)
                
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}
