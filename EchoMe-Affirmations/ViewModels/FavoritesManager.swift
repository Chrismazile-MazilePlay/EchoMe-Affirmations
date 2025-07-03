//
//  FavoritesManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Observation

@Observable
@MainActor
public class FavoritesManager {
    // Observable properties
    var favoriteIds: Set<String> = []
    var isListening = false
    
    // Dependencies
    weak var watchConnectivityManager: WatchConnectivityManager?
    
    // Private properties
    private var favoritesListener: ListenerRegistration?
    private var pendingSyncOperations: [PendingOperation] = []
    private var cachedFavorites: [String: FavoriteData] = [:]
    
    // Public initializer
    public init() {
        loadCachedFavorites()
        setupReachabilityObserver()
    }
    
    // MARK: - Optimistic Toggle
    
    func toggleFavoriteOptimistic(affirmationId: String, affirmationText: String) {
        // Toggle immediately in UI
        let wasFavorite = favoriteIds.contains(affirmationId)
        
        if wasFavorite {
            favoriteIds.remove(affirmationId)
            cachedFavorites.removeValue(forKey: affirmationId)
        } else {
            favoriteIds.insert(affirmationId)
            cachedFavorites[affirmationId] = FavoriteData(
                id: affirmationId,
                affirmationId: affirmationId,
                text: affirmationText,
                savedAt: Date()
            )
        }
        
        // Save to local cache
        saveCachedFavorites()
        
        // Send to watch immediately
        watchConnectivityManager?.sendFavoriteIds(Array(favoriteIds))
        
        // Queue Firebase sync
        queueFirebaseSync(
            affirmationId: affirmationId,
            affirmationText: affirmationText,
            isAdding: !wasFavorite
        )
    }
    
    // MARK: - Firebase Sync
    
    private func queueFirebaseSync(affirmationId: String, affirmationText: String, isAdding: Bool) {
        let operation = PendingOperation(
            affirmationId: affirmationId,
            affirmationText: affirmationText,
            isAdding: isAdding,
            timestamp: Date()
        )
        
        pendingSyncOperations.append(operation)
        
        // Try to sync immediately
        Task {
            await processPendingOperations()
        }
    }
    
    private func processPendingOperations() async {
        guard !pendingSyncOperations.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        var failedOperations: [PendingOperation] = []
        
        for operation in pendingSyncOperations {
            do {
                if operation.isAdding {
                    try await db.collection("users").document(userId)
                        .collection("favorites").document(operation.affirmationId)
                        .setData([
                            "affirmationId": operation.affirmationId,
                            "text": operation.affirmationText,
                            "savedAt": Timestamp(date: operation.timestamp)
                        ])
                    print("💖 Synced favorite to Firebase")
                } else {
                    try await db.collection("users").document(userId)
                        .collection("favorites").document(operation.affirmationId)
                        .delete()
                    print("💔 Removed favorite from Firebase")
                }
            } catch {
                print("❌ Failed to sync operation: \(error)")
                failedOperations.append(operation)
            }
        }
        
        // Keep failed operations for retry
        pendingSyncOperations = failedOperations
        
        if !failedOperations.isEmpty {
            // Retry failed operations after delay
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await processPendingOperations()
            }
        }
    }
    
    // MARK: - Listening
    
    func startListening() {
        guard !isListening,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        isListening = true
        
        favoritesListener = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("favorites")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to favorites: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    // Update from Firebase
                    let firebaseIds = Set(documents.map { $0.documentID })
                    
                    // Merge with local state (in case of pending operations)
                    self.mergeWithServerState(firebaseIds: firebaseIds, documents: documents)
                    
                    print("💖 Updated favorites: \(self.favoriteIds.count) items")
                    
                    // Send updated favorites to Watch
                    self.watchConnectivityManager?.sendFavoriteIds(Array(self.favoriteIds))
                }
            }
    }
    
    private func mergeWithServerState(firebaseIds: Set<String>, documents: [QueryDocumentSnapshot]) {
        // Update cached favorites from server
        for doc in documents {
            let data = doc.data()
            if let text = data["text"] as? String {
                cachedFavorites[doc.documentID] = FavoriteData(
                    id: doc.documentID,
                    affirmationId: doc.documentID,
                    text: text,
                    savedAt: (data["savedAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        }
        
        // Remove any that were deleted on server (unless we have pending add operations)
        let pendingAdds = Set(pendingSyncOperations.filter { $0.isAdding }.map { $0.affirmationId })
        let pendingRemoves = Set(pendingSyncOperations.filter { !$0.isAdding }.map { $0.affirmationId })
        
        // Update favorite IDs considering pending operations
        favoriteIds = firebaseIds
            .union(pendingAdds)
            .subtracting(pendingRemoves)
        
        saveCachedFavorites()
    }
    
    func stopListening() {
        favoritesListener?.remove()
        favoritesListener = nil
        isListening = false
    }
    
    // MARK: - Helper Methods
    
    func isFavorite(_ affirmationId: String) -> Bool {
        return favoriteIds.contains(affirmationId)
    }
    
    func getCachedFavorites() -> [FavoriteData] {
        return Array(cachedFavorites.values).sorted { $0.savedAt > $1.savedAt }
    }
    
    // MARK: - Local Cache
    
    private func loadCachedFavorites() {
        if let data = UserDefaults.standard.data(forKey: "cached_favorites"),
           let decoded = try? JSONDecoder().decode([String: FavoriteData].self, from: data) {
            cachedFavorites = decoded
            favoriteIds = Set(decoded.keys)
        }
    }
    
    private func saveCachedFavorites() {
        if let encoded = try? JSONEncoder().encode(cachedFavorites) {
            UserDefaults.standard.set(encoded, forKey: "cached_favorites")
        }
    }
    
    // MARK: - Reachability
    
    private func setupReachabilityObserver() {
        NotificationCenter.default.addObserver(
            forName: .init("NetworkReachabilityChanged"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.processPendingOperations()
            }
        }
    }
    
    // MARK: - Legacy Support
    
    func toggleFavorite(affirmationId: String, affirmationText: String, completion: ((Bool) -> Void)? = nil) {
        toggleFavoriteOptimistic(affirmationId: affirmationId, affirmationText: affirmationText)
        completion?(isFavorite(affirmationId))
    }
    
    // MARK: - Singleton
    static let shared = FavoritesManager()
}

// MARK: - Supporting Types

private struct PendingOperation: Codable {
    let affirmationId: String
    let affirmationText: String
    let isAdding: Bool
    let timestamp: Date
}

// Make FavoriteData Codable for local caching
extension FavoriteData: Codable {
    enum CodingKeys: String, CodingKey {
        case id, affirmationId, text, savedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        affirmationId = try container.decode(String.self, forKey: .affirmationId)
        text = try container.decode(String.self, forKey: .text)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(affirmationId, forKey: .affirmationId)
        try container.encode(text, forKey: .text)
        try container.encode(savedAt, forKey: .savedAt)
    }
}
