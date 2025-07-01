//
//  WatchConnectivityManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import WatchConnectivity
import Observation

@Observable
@MainActor
class WatchConnectivityManager: NSObject, @preconcurrency WatchConnectivityProtocol {
    static let shared = WatchConnectivityManager()
    
    // MARK: - Observable Properties
    var affirmations: [Affirmation] = []
    var favoriteIds: Set<String> = []
    var lastSyncDate: Date?
    var isReachable = false
    
    // MARK: - WatchConnectivityProtocol
    let session = WCSession.default
    
    private override init() {
        super.init()
        startSession()
    }
    
    // MARK: - Public Methods
    
    /// Request affirmations from iPhone
    func requestAffirmations() {
        guard session.isReachable else {
            print("⌚ iPhone not reachable")
            return
        }
        
        session.sendMessage(
            [WatchMessageKey.request: WatchMessageType.requestAffirmations],
            replyHandler: { response in
                print("⌚ Received response: \(response)")
            },
            errorHandler: { error in
                print("⌚ Error requesting affirmations: \(error)")
            }
        )
    }
    
    /// Toggle favorite status
    func toggleFavorite(affirmationId: String, affirmationText: String) {
        // Toggle local state immediately for responsive UI
        let wasFavorite = favoriteIds.contains(affirmationId)
        
        if wasFavorite {
            favoriteIds.remove(affirmationId)
        } else {
            favoriteIds.insert(affirmationId)
        }
        
        // Send to iPhone
        let message: [String: Any] = [
            WatchMessageType.type: WatchMessageType.favoriteToggle,
            WatchMessageKey.affirmationId: affirmationId,
            WatchMessageKey.affirmationText: affirmationText,
            WatchMessageKey.isFavorite: !wasFavorite
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { [weak self] error in
                print("⌚ Error sending favorite toggle: \(error)")
                // Revert on error
                Task { @MainActor in
                    if wasFavorite {
                        self?.favoriteIds.insert(affirmationId)
                    } else {
                        self?.favoriteIds.remove(affirmationId)
                    }
                }
            }
        }
    }
    
    // MARK: - WatchConnectivityProtocol Methods
    
    /// Send favorite IDs (Watch doesn't send IDs, it receives them)
    func sendFavoriteIds(_ favoriteIds: [String]) {
        // This is receive-only on Watch side
        self.favoriteIds = Set(favoriteIds)
        print("⌚ Updated favorite IDs: \(favoriteIds.count)")
    }
    
    /// Handle favorite toggle (not used on Watch side)
    func handleFavoriteToggle(_ message: [String: Any]) {
        // Watch sends toggles, doesn't receive them
    }
    
    // MARK: - Private Methods
    
    /// Update favorite IDs from iPhone
    private func updateFavoriteIds(_ ids: [String]) {
        favoriteIds = Set(ids)
        print("⌚ Updated favorite IDs: \(ids.count)")
    }
    
    /// Handle affirmations update from iPhone
    private func handleAffirmationsUpdate(_ data: [String: Any]) {
        if let affirmationData = data[WatchMessageKey.data] as? [[String: Any]] {
            let newAffirmations = affirmationData.compactMap { dict -> Affirmation? in
                guard let id = dict["id"] as? String,
                      let text = dict["text"] as? String else { return nil }
                
                let categories = dict["categories"] as? [String] ?? []
                let tone = dict["tone"] as? String ?? "gentle"
                let length = dict["length"] as? String ?? "short"
                let isActive = dict["isActive"] as? Bool ?? true
                
                return Affirmation(
                    id: id,
                    text: text,
                    categories: categories,
                    tone: tone,
                    length: length,
                    isActive: isActive,
                    createdAt: nil
                )
            }
            
            self.affirmations = newAffirmations
            self.lastSyncDate = Date()
            print("⌚ Updated affirmations: \(newAffirmations.count)")
        }
        
        // Also update favorite IDs if present
        if let favoriteIds = data[WatchMessageType.favoriteIds] as? [String] {
            updateFavoriteIds(favoriteIds)
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if activationState == .activated {
                self.isReachable = session.isReachable
                print("⌚ Session activated, reachable: \(session.isReachable)")
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("⌚ Reachability changed: \(session.isReachable)")
        }
    }
    
    // Handle messages from iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let type = message[WatchMessageType.type] as? String {
                switch type {
                case WatchMessageType.favoriteIds:
                    if let ids = message[WatchMessageType.favoriteIds] as? [String] {
                        self.updateFavoriteIds(ids)
                    }
                case WatchMessageType.affirmations:
                    self.handleAffirmationsUpdate(message)
                default:
                    break
                }
            }
        }
    }
    
    // Handle application context updates (for when watch wasn't reachable)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let type = applicationContext[WatchMessageType.type] as? String {
                switch type {
                case WatchMessageType.favoriteIds:
                    if let ids = applicationContext[WatchMessageType.favoriteIds] as? [String] {
                        self.updateFavoriteIds(ids)
                    }
                case WatchMessageType.affirmations:
                    self.handleAffirmationsUpdate(applicationContext)
                default:
                    break
                }
            }
        }
    }
}
