//
//  FavoritesManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

//
//  FavoritesManager.swift
//  EchoMe-Affirmations
//
//  Created on July 02, 2025.
//

import Foundation
import Observation

@Observable
@MainActor
public class FavoritesManager {
    // MARK: - Observable Properties
    var favoriteIds: Set<String> = []
    var isListening = false
    
    // MARK: - Dependencies
    weak var watchConnectivityManager: WatchConnectivityManager?
    private let firebaseService: FirebaseService
    
    // MARK: - Private Properties
    private var favoritesListener: FirebaseListener?
    private var pendingSyncOperations: [PendingOperation] = []
    private var cachedFavorites: [String: FavoriteData] = [:]
    
    // MARK: - Initialization
    public init(firebaseService: FirebaseService? = nil) {
        self.firebaseService = firebaseService ?? FirebaseService.shared
        loadCachedFavorites()
        setupReachabilityObserver()
    }
    
    // MARK: - Public Methods
    
    /// Toggle favorite with optimistic UI updates
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
    
    /// Start listening to favorites changes
    func startListening() {
        guard !isListening,
              let userId = firebaseService.currentAuthUser?.uid else { return }
        
        isListening = true
        
        favoritesListener = firebaseService.listenToFavorites(userId: userId) { [weak self] favorites in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Update from Firebase
                let firebaseIds = Set(favorites.map { $0.affirmationId })
                
                // Update cached favorites from server
                var updatedCache: [String: FavoriteData] = [:]
                for favorite in favorites {
                    updatedCache[favorite.affirmationId] = favorite
                }
                
                // Merge with local state
                self.mergeWithServerState(firebaseIds: firebaseIds, serverCache: updatedCache)
                
                print("💖 Updated favorites: \(self.favoriteIds.count) items")
                
                // Send updated favorites to Watch
                self.watchConnectivityManager?.sendFavoriteIds(Array(self.favoriteIds))
            }
        }
    }
    
    /// Stop listening
    func stopListening() {
        if let listener = favoritesListener {
            firebaseService.removeListener(listener)
            favoritesListener = nil
        }
        isListening = false
    }
    
    /// Check if an affirmation is favorited
    func isFavorite(_ affirmationId: String) -> Bool {
        return favoriteIds.contains(affirmationId)
    }
    
    /// Get cached favorites sorted by date
    func getCachedFavorites() -> [FavoriteData] {
        return Array(cachedFavorites.values).sorted { $0.savedAt > $1.savedAt }
    }
    
    /// Legacy support for completion-based toggle
    func toggleFavorite(affirmationId: String, affirmationText: String, completion: ((Bool) -> Void)? = nil) {
        toggleFavoriteOptimistic(affirmationId: affirmationId, affirmationText: affirmationText)
        completion?(isFavorite(affirmationId))
    }
    
    // MARK: - Private Methods
    
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
    
    private func mergeWithServerState(firebaseIds: Set<String>, serverCache: [String: FavoriteData]) {
        // Update cached favorites from server
        for (id, data) in serverCache {
            cachedFavorites[id] = data
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

// MARK: - Firebase Operations Extension
extension FavoritesManager {
    
    /// Process pending sync operations with Firebase
    func processPendingOperations() async {
        guard !pendingSyncOperations.isEmpty,
              let userId = firebaseService.currentAuthUser?.uid else { return }
        
        var failedOperations: [PendingOperation] = []
        
        for operation in pendingSyncOperations {
            do {
                if operation.isAdding {
                    try await firebaseService.addFavorite(
                        userId: userId,
                        affirmationId: operation.affirmationId,
                        text: operation.affirmationText
                    )
                    print("💖 Synced favorite to Firebase")
                } else {
                    try await firebaseService.removeFavorite(
                        userId: userId,
                        affirmationId: operation.affirmationId
                    )
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
}
