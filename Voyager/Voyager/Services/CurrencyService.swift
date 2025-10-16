import Foundation

class CurrencyService {
    static let shared = CurrencyService()
    
    private init() {}
    
    func convertCurrency(amount: Double, from: String, to: String) async throws -> (convertedAmount: Double, rate: Double) {
        let urlString = "\(Config.exchangeRateBaseURL)/\(from)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let currencyResponse = try JSONDecoder().decode(CurrencyResponse.self, from: data)
            
            guard let rate = currencyResponse.rates[to] else {
                throw NetworkError.currencyNotFound
            }
            
            let convertedAmount = amount * rate
            return (convertedAmount, rate)
            
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
    
    func getExchangeRate(from: String, to: String) async throws -> Double {
        let urlString = "\(Config.exchangeRateBaseURL)/\(from)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let currencyResponse = try JSONDecoder().decode(CurrencyResponse.self, from: data)
        
        guard let rate = currencyResponse.rates[to] else {
            throw NetworkError.currencyNotFound
        }
        
        return rate
    }
}
