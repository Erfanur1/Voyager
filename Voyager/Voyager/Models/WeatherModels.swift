import Foundation

struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [Weather]
    let name: String
    let wind: Wind
    let sys: Sys
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        let pressure: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
            case pressure
        }
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
    
    struct Sys: Codable {
        let country: String
    }
    
    var tempCelsius: String {
        String(format: "%.0f°C", main.temp)
    }
    
    var feelsLikeCelsius: String {
        String(format: "%.0f°C", main.feelsLike)
    }
    
    var weatherIconURL: URL? {
        URL(string: "https://openweathermap.org/img/wn/\(weather.first?.icon ?? "01d")@2x.png")
    }
    
    var weatherEmoji: String {
        guard let weatherId = weather.first?.id else { return "☀️" }
        
        switch weatherId {
        case 200...232: return "⛈️" // Thunderstorm
        case 300...321: return "🌦️" // Drizzle
        case 500...531: return "🌧️" // Rain
        case 600...622: return "❄️" // Snow
        case 701...781: return "🌫️" // Atmosphere
        case 800: return "☀️" // Clear
        case 801...804: return "☁️" // Clouds
        default: return "🌤️"
        }
    }
}

struct CurrencyResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

struct CountryResponse: Codable {
    let name: CountryName
    let capital: [String]?
    let population: Int
    let flags: Flags
    let timezones: [String]
    let currencies: [String: Currency]?
    let languages: [String: String]?
    let latlng: [Double]?
    
    struct CountryName: Codable {
        let common: String
        let official: String
    }
    
    struct Flags: Codable {
        let png: String
        let svg: String?
    }
    
    struct Currency: Codable {
        let name: String
        let symbol: String?
    }
    
    var flagURL: URL? {
        URL(string: flags.png)
    }
    
    var primaryCurrency: String {
        currencies?.values.first?.name ?? "Unknown"
    }
    
    var primaryLanguage: String {
        languages?.values.first ?? "Unknown"
    }
    
    var capitalCity: String {
        capital?.first ?? "Unknown"
    }
    
    var formattedPopulation: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: population)) ?? "\(population)"
    }
}
