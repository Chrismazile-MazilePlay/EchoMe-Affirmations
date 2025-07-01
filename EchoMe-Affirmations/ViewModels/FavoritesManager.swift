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
class FavoritesManager {
    static let shared = FavoritesManager()
    
    // Observable properties
    var favoriteIds: Set<String> = []
    var isListening = false
    
    private var favoritesListener: ListenerRegistration?
    
    private init() {}
    
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
    
    // Toggle favorite (called from AffirmationCard)
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
                }
            }
        }
    }
}
