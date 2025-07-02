//
//  FavoritesManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import Observation

@Observable
@MainActor
public class FavoritesManager {
    // Observable properties
    var favoriteIds: Set<String> = []
    var isListening = false
    
    // Dependencies
    weak var watchConnectivityManager: WatchConnectivityManager?
    private let firebaseService: FirebaseService
    private var favoritesListener: FirebaseListener?
    
    // Public initializer
    public init(firebaseService: FirebaseService? = nil) {
        self.firebaseService = firebaseService ?? FirebaseService.shared
    }
    
    // Start listening to favorites changes
    func startListening() {
        guard !isListening,
              let userId = firebaseService.currentAuthUser?.uid else { return }
        
        isListening = true
        
        favoritesListener = firebaseService.listenToFavorites(userId: userId) { [weak self] favorites in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Update favorite IDs
                let ids = Set(favorites.map { $0.affirmationId })
                self.favoriteIds = ids
                print("💖 Updated favorites: \(ids.count) items")
                
                // Send updated favorites to Watch
                self.watchConnectivityManager?.sendFavoriteIds(Array(ids))
            }
        }
    }
    
    // Stop listening
    func stopListening() {
        if let listener = favoritesListener {
            firebaseService.removeListener(listener)
            favoritesListener = nil
        }
        isListening = false
    }
    
    // Check if an affirmation is favorited
    func isFavorite(_ affirmationId: String) -> Bool {
        return favoriteIds.contains(affirmationId)
    }
    
    // Toggle favorite
    func toggleFavorite(affirmationId: String, affirmationText: String) {
        guard let userId = firebaseService.currentAuthUser?.uid else { return }
        
        let isFavorite = isFavorite(affirmationId)
        
        Task {
            do {
                if isFavorite {
                    try await firebaseService.removeFavorite(
                        userId: userId,
                        affirmationId: affirmationId
                    )
                    print("💔 Removed from favorites")
                } else {
                    try await firebaseService.addFavorite(
                        userId: userId,
                        affirmationId: affirmationId,
                        text: affirmationText
                    )
                    print("💖 Added to favorites")
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
}
