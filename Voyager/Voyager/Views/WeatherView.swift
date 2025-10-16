import SwiftUI

struct WeatherView: View {
    let destination: String
    @State private var weather: WeatherResponse?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .padding()
            } else if let weather = weather {
                weatherContent(weather)
            } else {
                emptyState
            }
        }
    }
    
    @ViewBuilder
    private func weatherContent(_ weather: WeatherResponse) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Weather")
                    .font(.headline)
                Spacer()
                Button(action: { Task { await fetchWeather() } }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 20) {
                // Weather icon
                Text(weather.weatherEmoji)
                    .font(.system(size: 60))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.tempCelsius)
                        .font(.system(size: 36, weight: .bold))
                    
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Feels like \(weather.feelsLikeCelsius)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 30) {
                WeatherDetailItem(icon: "humidity", value: "\(weather.main.humidity)%", label: "Humidity")
                WeatherDetailItem(icon: "wind", value: String(format: "%.1f m/s", weather.wind.speed), label: "Wind")
                WeatherDetailItem(icon: "gauge", value: "\(weather.main.pressure) hPa", label: "Pressure")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Weather Unavailable")
                .font(.headline)
            
            Button("Load Weather") {
                Task { await fetchWeather() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func fetchWeather() async {
        isLoading = true
        error = nil
        
        do {
            let weatherData = try await WeatherService.shared.fetchWeather(for: destination)
            await MainActor.run {
                self.weather = weatherData
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

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Mini weather widget for trip cards
struct MiniWeatherView: View {
    let destination: String
    @State private var weather: WeatherResponse?
    
    var body: some View {
        HStack(spacing: 8) {
            if let weather = weather {
                Text(weather.weatherEmoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(weather.tempCelsius)
                        .font(.headline)
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Image(systemName: "cloud")
                    .foregroundColor(.secondary)
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await fetchWeather()
        }
    }
    
    private func fetchWeather() async {
        do {
            let weatherData = try await WeatherService.shared.fetchWeather(for: destination)
            await MainActor.run {
                self.weather = weatherData
            }
        } catch {
            // Silently fail for mini widget
        }
    }
}
