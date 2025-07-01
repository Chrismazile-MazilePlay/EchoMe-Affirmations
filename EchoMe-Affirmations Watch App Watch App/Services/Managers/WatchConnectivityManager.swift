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
    var affirmations: [Affirmation] = []
    var userCategories: [String] = []
    var favoriteIds: Set<String> = []  // Track favorite IDs
    var lastSyncDate: Date?
    var isConnected = false
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupSession()
        loadCachedData()
    }
    
    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // Toggle favorite and sync with iPhone
    func toggleFavorite(affirmationId: String, affirmationText: String, isFavorite: Bool) {
        print("⌚ Toggling favorite: \(affirmationId) - \(isFavorite)")
        
        // Update local state
        if isFavorite {
            favoriteIds.insert(affirmationId)
        } else {
            favoriteIds.remove(affirmationId)
        }
        
        // Save locally
        saveFavoriteIds()
        
        // Send to iPhone
        guard let session = session else { return }
        
        let message: [String: Any] = [
            "type": "favoriteToggle",
            "affirmationId": affirmationId,
            "affirmationText": affirmationText,
            "isFavorite": isFavorite,
            "timestamp": Date()
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                print("✅ Watch: iPhone acknowledged favorite toggle")
            }) { error in
                print("❌ Watch: Error sending favorite toggle: \(error)")
            }
        } else {
            // Queue for later if iPhone not reachable
            do {
                var context = session.applicationContext
                var queuedFavorites = context["queuedFavorites"] as? [[String: Any]] ?? []
                queuedFavorites.append(message)
                context["queuedFavorites"] = queuedFavorites
                try session.updateApplicationContext(context)
            } catch {
                print("❌ Watch: Failed to queue favorite: \(error)")
            }
        }
    }
    
    // Request affirmations from iPhone
    func requestAffirmations() {
        print("⌚ Requesting affirmations from iPhone")
        
        guard let session = session else {
            print("❌ Watch: No session available")
            return
        }
        
        print("⌚ Session activation state: \(session.activationState.rawValue)")
        print("⌚ Session reachable: \(session.isReachable)")
        
        if session.isReachable {
            let message = ["request": "affirmations"]
            session.sendMessage(message, replyHandler: { response in
                print("✅ Watch: iPhone responded: \(response)")
            }) { error in
                print("❌ Watch: Error requesting: \(error)")
            }
        } else {
            print("⌚ iPhone not reachable, checking for cached context")
            let context = session.receivedApplicationContext
            if let type = context["type"] as? String, type == "affirmations" {
                handleAffirmationsMessage(context)
            }
        }
    }
    
    // Save data locally
    private func saveDataLocally() {
        let encoder = JSONEncoder()
        
        if let affirmationData = try? encoder.encode(affirmations) {
            UserDefaults.standard.set(affirmationData, forKey: "cachedAffirmations")
        }
        
        UserDefaults.standard.set(userCategories, forKey: "cachedCategories")
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
        saveFavoriteIds()
    }
    
    private func saveFavoriteIds() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: "favoriteIds")
    }
    
    private func loadCachedData() {
        let decoder = JSONDecoder()
        
        if let affirmationData = UserDefaults.standard.data(forKey: "cachedAffirmations"),
           let cached = try? decoder.decode([Affirmation].self, from: affirmationData) {
            self.affirmations = cached
            print("⌚ Loaded \(cached.count) cached affirmations")
        }
        
        if let categories = UserDefaults.standard.stringArray(forKey: "cachedCategories") {
            self.userCategories = categories
        }
        
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: "favoriteIds") {
            self.favoriteIds = Set(savedFavorites)
        }
        
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
    
    // Handle received messages
    private func handleAffirmationsMessage(_ message: [String: Any]) {
        print("⌚ Processing affirmations message")
        guard let data = message["data"] as? [[String: Any]] else {
            print("❌ Watch: No data in message")
            return
        }
        
        let newAffirmations = data.compactMap { dict -> Affirmation? in
            guard let id = dict["id"] as? String,
                  let text = dict["text"] as? String else { return nil }
            
            return Affirmation(
                id: id,
                text: text,
                categories: dict["categories"] as? [String] ?? [],
                tone: dict["tone"] as? String ?? "gentle",
                length: dict["length"] as? String ?? "short"
            )
        }
        
        print("⌚ Received \(newAffirmations.count) affirmations")
        self.affirmations = newAffirmations
        self.lastSyncDate = Date()
        saveDataLocally()
    }
    
    private func handlePreferencesMessage(_ message: [String: Any]) {
        if let categories = message["categories"] as? [String] {
            self.userCategories = categories
        }
        
        if let favoriteIdArray = message["favoriteIds"] as? [String] {
            self.favoriteIds = Set(favoriteIdArray)
            print("⌚ Updated favorite IDs: \(favoriteIds.count) favorites")
        }
        
        saveDataLocally()
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("⌚ Session activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("❌ Watch activation error: \(error)")
        }
        
        if activationState == .activated {
            Task { @MainActor in
                self.isConnected = session.isReachable
                print("⌚ Session activated, reachable: \(session.isReachable)")
                
                let context = session.receivedApplicationContext
                if let type = context["type"] as? String, type == "affirmations" {
                    print("⌚ Found cached context on activation")
                    self.handleAffirmationsMessage(context)
                } else {
                    self.requestAffirmations()
                }
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("⌚ Received message: \(message["type"] ?? "unknown")")
        Task { @MainActor in
            if let type = message["type"] as? String {
                switch type {
                case "affirmations":
                    self.handleAffirmationsMessage(message)
                case "preferences":
                    self.handlePreferencesMessage(message)
                case "favoriteUpdate":
                    // Handle favorite updates from iPhone
                    if let favoriteIds = message["favoriteIds"] as? [String] {
                        self.favoriteIds = Set(favoriteIds)
                        self.saveFavoriteIds()
                    }
                default:
                    print("⌚ Unknown message type: \(type)")
                }
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("⌚ Received application context update")
        Task { @MainActor in
            if let type = applicationContext["type"] as? String, type == "affirmations" {
                self.handleAffirmationsMessage(applicationContext)
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isConnected = session.isReachable
            print("⌚ Reachability changed to: \(session.isReachable)")
            
            if session.isReachable {
                self.requestAffirmations()
            }
        }
    }
}
