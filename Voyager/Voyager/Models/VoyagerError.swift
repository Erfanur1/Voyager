import Foundation
import SwiftUI

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound
    case currencyNotFound
    case decodingError(Error)
    case serverError(statusCode: Int)
    case noInternetConnection
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .invalidResponse:
            return "Unable to connect to the server. Check your internet connection."
        case .notFound:
            return "The requested information could not be found."
        case .currencyNotFound:
            return "Currency conversion rate not available."
        case .decodingError:
            return "Unable to process the data. Please try again."
        case .serverError(let code):
            return "Server error (Code: \(code)). Please try again later."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Check your WiFi or cellular connection"
        case .timeout:
            return "Your connection might be slow. Try again."
        case .notFound:
            return "Try searching with a different name"
        default:
            return "Pull to refresh or try again later"
        }
    }
}

enum DataError: LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data. Please try again."
        case .fetchFailed:
            return "Failed to load data. Please restart the app."
        case .deleteFailed:
            return "Failed to delete item. Please try again."
        case .invalidData:
            return "Invalid data format."
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access denied. Enable in Settings."
        case .locationUnavailable:
            return "Unable to determine your location."
        case .geocodingFailed:
            return "Unable to find location coordinates."
        }
    }
}

// Error Alert View Modifier
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { _ in
                Button("OK") { error = nil }
            } message: { error in
                VStack {
                    Text(error.localizedDescription)
                    if let networkError = error as? NetworkError,
                       let suggestion = networkError.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
