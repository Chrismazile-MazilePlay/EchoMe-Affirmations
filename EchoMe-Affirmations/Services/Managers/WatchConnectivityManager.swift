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
class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    
    var isReachable = false
    private var session: WCSession?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // Send affirmations and favorites to watch
    func sendAffirmationsToWatch(_ affirmations: [Affirmation]) {
        print("📱 WatchConnectivity - Attempting to send affirmations")
        print("📱 Session supported: \(WCSession.isSupported())")
        print("📱 Session reachable: \(session?.isReachable ?? false)")
        
        guard let session = session else {
            print("❌ No session available")
            return
        }
        
        // Get current favorite IDs
        Task {
            let favoriteIds = await getFavoriteIds()
            
            if session.isReachable {
                sendViaMessage(affirmations, favoriteIds: favoriteIds)
            } else {
                sendViaApplicationContext(affirmations, favoriteIds: favoriteIds)
            }
        }
    }
    
    private func sendViaMessage(_ affirmations: [Affirmation], favoriteIds: [String]) {
        guard let session = session else { return }
        
        let affirmationData = affirmations.prefix(5).map { affirmation in
            [
                "id": affirmation.id ?? UUID().uuidString,
                "text": affirmation.text,
                "categories": affirmation.categories
            ]
        }
        
        let message: [String: Any] = [
            "type": "affirmations",
            "data": affirmationData,
            "timestamp": Date()
        ]
        
        session.sendMessage(message, replyHandler: { response in
            print("✅ Watch acknowledged: \(response)")
        }) { error in
            print("❌ Error sending to watch: \(error)")
            self.sendViaApplicationContext(affirmations, favoriteIds: favoriteIds)
        }
    }
    
    // Send user preferences including favorites
    func sendPreferencesToWatch(categories: [String], voiceProfile: String) {
        print("📱 Sending preferences to watch")
        
        guard let session = session else {
            print("❌ No session for preferences")
            return
        }
        
        Task {
            let favoriteIds = await getFavoriteIds()
            
            if session.isReachable {
                let message: [String: Any] = [
                    "type": "preferences",
                    "categories": categories,
                    "voiceProfile": voiceProfile,
                    "favoriteIds": favoriteIds
                ]
                
                session.sendMessage(message, replyHandler: nil) { error in
                    print("❌ Error sending preferences: \(error)")
                }
            }
        }
    }
    
    // Get current favorite IDs from Firestore
    private func getFavoriteIds() async -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("favorites")
                .getDocuments()
            
            return snapshot.documents.map { $0.documentID }
        } catch {
            print("❌ Error fetching favorite IDs: \(error)")
            return []
        }
    }
    
    // Backup method using application context
    private func sendViaApplicationContext(_ affirmations: [Affirmation], favoriteIds: [String]) {
        guard let session = session else { return }
        
        let affirmationData = affirmations.prefix(5).map { affirmation in
            [
                "id": affirmation.id ?? UUID().uuidString,
                "text": affirmation.text,
                "categories": affirmation.categories
            ]
        }
        
        let context: [String: Any] = [
            "type": "affirmations",
            "data": affirmationData,
            "favoriteIds": favoriteIds,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try session.updateApplicationContext(context)
            print("✅ Sent via application context")
        } catch {
            print("❌ Failed to update application context: \(error)")
        }
    }
    
    // Handle favorite toggle from watch
    private func handleFavoriteToggle(_ message: [String: Any]) {
        guard let affirmationId = message["affirmationId"] as? String,
              let affirmationText = message["affirmationText"] as? String,
              let isFavorite = message["isFavorite"] as? Bool,
              let userId = Auth.auth().currentUser?.uid else {
            print("❌ Invalid favorite toggle message")
            return
        }
        
        print("📱 Processing favorite toggle: \(affirmationId) - \(isFavorite)")
        
        let db = Firestore.firestore()
        let favoriteRef = db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
        
        if isFavorite {
            // Add to favorites
            favoriteRef.setData([
                "affirmationId": affirmationId,
                "text": affirmationText,
                "savedAt": Date()
            ]) { error in
                if let error = error {
                    print("❌ Error adding favorite: \(error)")
                } else {
                    print("✅ Added to favorites - Firestore listeners will update UI")
                    // The FavoritesManager will automatically detect this change
                    self.sendUpdatedFavoritesToWatch()
                }
            }
        } else {
            // Remove from favorites
            favoriteRef.delete { error in
                if let error = error {
                    print("❌ Error removing favorite: \(error)")
                } else {
                    print("✅ Removed from favorites - Firestore listeners will update UI")
                    // The FavoritesManager will automatically detect this change
                    self.sendUpdatedFavoritesToWatch()
                }
            }
        }
    }
    
    // Send updated favorites list back to watch
    private func sendUpdatedFavoritesToWatch() {
        Task {
            let favoriteIds = await getFavoriteIds()
            
            guard let session = session, session.isReachable else { return }
            
            let message: [String: Any] = [
                "type": "favoriteUpdate",
                "favoriteIds": favoriteIds
            ]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Error sending favorite update: \(error)")
            }
        }
    }
    
    // Handle requests from watch
    private func handleWatchRequest(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let request = message["request"] as? String, request == "affirmations" {
            print("📱 Watch requested affirmations")
            replyHandler(["status": "acknowledged"])
            
            // Trigger a refresh - you might want to notify ContentView to refresh
            // For now, just acknowledge
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
            if let type = message["type"] as? String, type == "favoriteToggle" {
                self.handleFavoriteToggle(message)
                replyHandler(["status": "received"])
            } else {
                self.handleWatchRequest(message, replyHandler: replyHandler)
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let type = message["type"] as? String, type == "favoriteToggle" {
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
