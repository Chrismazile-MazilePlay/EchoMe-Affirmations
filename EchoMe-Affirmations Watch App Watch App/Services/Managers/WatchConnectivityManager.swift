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
class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    
    // Observable properties
    var affirmations: [(id: String, text: String)] = []
    var favoriteIds: Set<String> = []
    var lastSyncDate: Date?
    var isReachable = false
    
    private let session = WCSession.default
    
    private override init() {
        super.init()
    }
    
    func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func requestAffirmations() {
        guard session.isReachable else {
            print("⌚ iPhone not reachable")
            return
        }
        
        session.sendMessage(
            ["request": "affirmations"],
            replyHandler: { response in
                print("⌚ Received response: \(response)")
            },
            errorHandler: { error in
                print("⌚ Error requesting affirmations: \(error)")
            }
        )
    }
    
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
            "type": "favoriteToggle",
            "affirmationId": affirmationId,
            "affirmationText": affirmationText,
            "isFavorite": !wasFavorite
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("⌚ Error sending favorite toggle: \(error)")
                // Revert on error
                if wasFavorite {
                    self.favoriteIds.insert(affirmationId)
                } else {
                    self.favoriteIds.remove(affirmationId)
                }
            }
        }
    }
    
    private func updateFavoriteIds(_ ids: [String]) {
        favoriteIds = Set(ids)
        print("⌚ Updated favorite IDs: \(ids.count)")
    }
    
    private func handleAffirmationsUpdate(_ data: [String: Any]) {
        if let affirmationData = data["data"] as? [[String: Any]] {
            let newAffirmations = affirmationData.compactMap { dict -> (id: String, text: String)? in
                guard let id = dict["id"] as? String,
                      let text = dict["text"] as? String else { return nil }
                return (id: id, text: text)
            }
            
            self.affirmations = newAffirmations
            self.lastSyncDate = Date()
            print("⌚ Updated affirmations: \(newAffirmations.count)")
        }
        
        // Also update favorite IDs if present
        if let favoriteIds = data["favoriteIds"] as? [String] {
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
            if let type = message["type"] as? String {
                switch type {
                case "favoriteIds":
                    if let ids = message["favoriteIds"] as? [String] {
                        self.updateFavoriteIds(ids)
                    }
                case "affirmations":
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
            if let type = applicationContext["type"] as? String {
                switch type {
                case "favoriteIds":
                    if let ids = applicationContext["favoriteIds"] as? [String] {
                        self.updateFavoriteIds(ids)
                    }
                case "affirmations":
                    self.handleAffirmationsUpdate(applicationContext)
                default:
                    break
                }
            }
        }
    }
}
