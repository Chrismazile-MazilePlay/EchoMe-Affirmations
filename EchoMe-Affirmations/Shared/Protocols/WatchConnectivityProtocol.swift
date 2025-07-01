//
//  WatchConnectivityProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import WatchConnectivity

/// Shared protocol for Watch Connectivity functionality
protocol WatchConnectivityProtocol: AnyObject {
    // MARK: - Properties
    var isReachable: Bool { get }
    var session: WCSession { get }
    
    // MARK: - Session Management
    func startSession()
    
    // MARK: - Data Transfer
    func sendFavoriteIds(_ favoriteIds: [String])
    
    // MARK: - Common Message Types
    func handleFavoriteToggle(_ message: [String: Any])
}

// MARK: - Default Implementations
extension WatchConnectivityProtocol {
    /// Start the WatchConnectivity session
    func startSession() {
        if WCSession.isSupported() {
            session.delegate = self as? WCSessionDelegate
            session.activate()
        }
    }
    
    /// Check if the counterpart is reachable
    var isReachable: Bool {
        return session.isReachable
    }
}

// MARK: - Message Type Constants
enum WatchMessageType {
    static let favoriteIds = "favoriteIds"
    static let favoriteToggle = "favoriteToggle"
    static let affirmations = "affirmations"
    static let requestAffirmations = "request"
    static let preferences = "preferences"
    static let type = "type"
    static let timestamp = "timestamp"
}

// MARK: - Message Keys
enum WatchMessageKey {
    static let affirmationId = "affirmationId"
    static let affirmationText = "affirmationText"
    static let isFavorite = "isFavorite"
    static let data = "data"
    static let categories = "categories"
    static let voiceProfile = "voiceProfile"
    static let status = "status"
    static let request = "request"
}
