//
//  WatchConnectivityManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import WatchConnectivity
import FirebaseFirestore
import FirebaseAuth
import Observation

@Observable
@MainActor
class WatchConnectivityManager: NSObject, @preconcurrency WatchConnectivityProtocol {    
    // MARK: - Observable Properties
    var isReachable = false
    var isPaired = false
    var isWatchAppInstalled = false
    
    // MARK: - WatchConnectivityProtocol
    let session: WCSession
    
    public override init() {
        self.session = WCSession.default
        super.init()
        startSession()
    }
    
    // MARK: - Send Methods
    
    /// Send affirmations to watch
    func sendAffirmationsToWatch(_ affirmations: [Affirmation]) {
        guard session.activationState == .activated else { return }
        
        let affirmationData = affirmations.map { affirmation in
            [
                "id": affirmation.id,
                "text": affirmation.text,
                "categories": affirmation.categories,
                "tone": affirmation.tone,
                "length": affirmation.length,
                "isActive": affirmation.isActive
            ]
        }
        
        // Get current favorite IDs
        let favoriteIds = Array(FavoritesManager().favoriteIds)
        
        let context: [String: Any] = [
            WatchMessageType.type: WatchMessageType.affirmations,
            WatchMessageKey.data: affirmationData,
            WatchMessageType.favoriteIds: favoriteIds,
            WatchMessageType.timestamp: Date().timeIntervalSince1970
        ]
        
        do {
            try session.updateApplicationContext(context)
            print("✅ Sent affirmations and favorites via context")
        } catch {
            print("❌ Failed to update application context: \(error)")
        }
    }
    
    /// Send favorite IDs to Watch (from protocol)
    func sendFavoriteIds(_ favoriteIds: [String]) {
        guard session.activationState == .activated else { return }
        
        // Send via immediate message if reachable
        if session.isReachable {
            session.sendMessage([
                WatchMessageType.type: WatchMessageType.favoriteIds,
                WatchMessageType.favoriteIds: favoriteIds
            ], replyHandler: nil) { error in
                print("❌ Failed to send favorite IDs: \(error)")
            }
        }
        
        // Always update context for persistence
        do {
            try session.updateApplicationContext([
                WatchMessageType.type: WatchMessageType.favoriteIds,
                WatchMessageType.favoriteIds: favoriteIds,
                WatchMessageType.timestamp: Date().timeIntervalSince1970
            ])
            print("✅ Updated favorite IDs in context")
        } catch {
            print("❌ Failed to update context: \(error)")
        }
    }
    
    // MARK: - Handle Methods
    
    /// Handle favorite toggle from watch (from protocol)
    func handleFavoriteToggle(_ message: [String: Any]) {
        guard let affirmationId = message[WatchMessageKey.affirmationId] as? String,
              let affirmationText = message[WatchMessageKey.affirmationText] as? String,
              let isFavorite = message[WatchMessageKey.isFavorite] as? Bool,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let favoriteRef = db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
        
        if isFavorite {
            favoriteRef.setData([
                "affirmationId": affirmationId,
                "text": affirmationText,
                "savedAt": Date()
            ]) { error in
                if let error = error {
                    print("❌ Error adding favorite: \(error)")
                } else {
                    print("✅ Added to favorites - Firestore listeners will update UI")
                }
            }
        } else {
            favoriteRef.delete { error in
                if let error = error {
                    print("❌ Error removing favorite: \(error)")
                } else {
                    print("✅ Removed from favorites - Firestore listeners will update UI")
                }
            }
        }
    }
    
    /// Handle watch requests
    private func handleWatchRequest(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let request = message[WatchMessageKey.request] as? String,
           request == WatchMessageType.requestAffirmations {
            print("📱 Watch requested affirmations")
            replyHandler([WatchMessageKey.status: "acknowledged"])
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            print("📱 Session activation: \(activationState.rawValue)")
            if activationState == .activated {
                self.isReachable = session.isReachable
                self.isPaired = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("📱 Reachability changed: \(session.isReachable)")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            if let type = message[WatchMessageType.type] as? String,
               type == WatchMessageType.favoriteToggle {
                self.handleFavoriteToggle(message)
                replyHandler([WatchMessageKey.status: "received"])
            } else {
                self.handleWatchRequest(message, replyHandler: replyHandler)
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let type = message[WatchMessageType.type] as? String,
               type == WatchMessageType.favoriteToggle {
                self.handleFavoriteToggle(message)
            }
        }
    }
    
    // iOS only delegates
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
