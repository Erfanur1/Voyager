import SwiftUI

struct CountryInfoView: View {
    let destination: String
    @State private var countryInfo: CountryResponse?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let info = countryInfo {
                countryContent(info)
            } else {
                emptyState
            }
        }
        .task {
            await fetchCountryInfo()
        }
    }
    
    @ViewBuilder
    private func countryContent(_ info: CountryResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Destination Info")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                if let flagURL = info.flagURL {
                    AsyncImage(url: flagURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 60)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 60)
                            .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.name.common)
                        .font(.title3)
                        .bold()
                    
                    Label(info.capitalCity, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InfoCard(icon: "person.3.fill", title: "Population", value: info.formattedPopulation)
                InfoCard(icon: "dollarsign.circle.fill", title: "Currency", value: info.primaryCurrency)
                InfoCard(icon: "bubble.left.and.bubble.right.fill", title: "Language", value: info.primaryLanguage)
                InfoCard(icon: "clock.fill", title: "Timezone", value: info.timezones.first?.replacingOccurrences(of: "UTC", with: "") ?? "")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Country Info Unavailable")
                .font(.headline)
            
            if let error = error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                Task { await fetchCountryInfo() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func fetchCountryInfo() async {
        isLoading = true
        error = nil
        
        do {
            let info = try await CountryService.shared.fetchCountryInfo(for: destination)
            await MainActor.run {
                self.countryInfo = info
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
