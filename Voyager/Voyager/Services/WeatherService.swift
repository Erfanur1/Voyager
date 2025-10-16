import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func fetchWeather(for city: String) async throws -> WeatherResponse {
        // Remove any extra whitespace or special characters
        let cleanCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cleanCity)&appid=\(Config.weatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    return weatherResponse
                } catch {
                    print("Decoding error: \(error)")
                    throw NetworkError.decodingError(error)
                }
            case 404:
                throw NetworkError.notFound
            case 401:
                throw NetworkError.serverError(statusCode: 401)
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                throw NetworkError.noInternetConnection
            } else if (error as NSError).code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            }
            throw NetworkError.invalidResponse
        }
    }
}
