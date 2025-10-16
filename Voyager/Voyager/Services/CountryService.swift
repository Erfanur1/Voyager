import Foundation

class CountryService {
    static let shared = CountryService()
    
    private init() {}
    
    func fetchCountryInfo(for destination: String) async throws -> CountryResponse {
        // Extract country name from destination (e.g., "Paris, France" -> "France")
        let countryName = destination.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? destination
        
        let cleanName = countryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? countryName
        
        let urlString = "\(Config.countriesBaseURL)/name/\(cleanName)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw NetworkError.notFound
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let countries = try JSONDecoder().decode([CountryResponse].self, from: data)
            
            guard let countryInfo = countries.first else {
                throw NetworkError.notFound
            }
            
            return countryInfo
            
        } catch let error as NetworkError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                throw NetworkError.noInternetConnection
            } else if (error as NSError).code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            }
            throw NetworkError.decodingError(error)
        }
    }
}
