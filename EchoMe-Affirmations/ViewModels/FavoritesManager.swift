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
    
    private var favoritesListener: ListenerRegistration?
    
    // Public initializer
    public init() {}
    
    // Start listening to favorites changes
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
                
                // Update favorite IDs
                let ids = Set(documents.map { $0.documentID })
                
                Task { @MainActor in
                    self.favoriteIds = ids
                    print("💖 Updated favorites: \(ids.count) items")
                    
                    // Send updated favorites to Watch
                    self.watchConnectivityManager?.sendFavoriteIds(Array(ids))
                }
            }
    }
    
    // Stop listening
    func stopListening() {
        favoritesListener?.remove()
        favoritesListener = nil
        isListening = false
    }
    
    // Check if an affirmation is favorited
    func isFavorite(_ affirmationId: String) -> Bool {
        return favoriteIds.contains(affirmationId)
    }
    
    // Toggle favorite
    func toggleFavorite(affirmationId: String, affirmationText: String, completion: ((Bool) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let isFavorite = isFavorite(affirmationId)
        let db = Firestore.firestore()
        let favoriteRef = db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
        
        if isFavorite {
            // Remove from favorites
            favoriteRef.delete { error in
                if error == nil {
                    completion?(false)
                    print("💔 Removed from favorites")
                }
            }
        } else {
            // Add to favorites
            favoriteRef.setData([
                "affirmationId": affirmationId,
                "text": affirmationText,
                "savedAt": Date()
            ]) { error in
                if error == nil {
                    completion?(true)
                    print("💖 Added to favorites")
                }
            }
        }
    }
}
