//
//  ppError.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import Foundation

enum AppError: LocalizedError, Equatable {
    case notAuthenticated
    case networkError(String)
    case dataNotFound
    case custom(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .networkError(let message):
            return "Network error: \(message)"
        case .dataNotFound:
            return "The requested data could not be found"
        case .custom(let message):
            return message
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Equatable
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated):
            return true
        case (.networkError(let lhsMessage), .networkError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.dataNotFound, .dataNotFound):
            return true
        case (.custom(let lhsMessage), .custom(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
