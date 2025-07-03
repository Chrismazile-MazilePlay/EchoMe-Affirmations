//
//  FavoritesViewModel.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class FavoritesViewModel {
    // MARK: - State
    var favorites: [Affirmation] = []
    var isLoading = false
    var error: AppError?
    var searchText = ""
    
    // MARK: - Computed Properties
    var filteredFavorites: [Affirmation] {
        if searchText.isEmpty {
            return favorites
        }
        return favorites.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var isEmpty: Bool {
        favorites.isEmpty
    }
    
    // MARK: - Dependencies
    private var services: ServicesContainer?
    private var favoritesListener: FirebaseListener?
    
    // MARK: - Setup
    func setup(with services: ServicesContainer) {
        self.services = services
        
        if MockDataProvider.isPreview {
            loadMockFavorites()
        } else {
            loadFavorites()
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        favoritesListener?.remove()
        favoritesListener = nil
    }
    
    // MARK: - Data Loading
    func loadFavorites() {
        guard let services = services,
              let userId = services.authManager.currentUser?.uid else {
            Logger.error("No user ID available for favorites")
            return
        }
        
        isLoading = true
        error = nil
        
        // Listen to favorites using the existing FirebaseService method
        favoritesListener = services.firebaseService.listenToFavorites(userId: userId) { [weak self] favoriteData in
            guard let self = self else { return }
            
            // Convert FavoriteData to Affirmation objects
            self.favorites = favoriteData.map { data in
                Affirmation(
                    id: data.affirmationId,
                    text: data.text,
                    categories: [],
                    tone: "gentle",
                    length: "short",
                    isActive: true,
                    createdAt: data.savedAt
                )
            }
            
            self.isLoading = false
            Logger.success("Loaded \(self.favorites.count) favorites")
        }
    }
    
    // MARK: - Actions
    func removeFavorite(_ affirmation: Affirmation) async {
        guard let services = services,
              let userId = services.authManager.currentUser?.uid else { return }
        
        do {
            try await services.firebaseService.removeFavorite(
                userId: userId,
                affirmationId: affirmation.id
            )
            
            // The listener will automatically update the favorites array
            Logger.info("Removed favorite: \(affirmation.id)")
        } catch {
            Logger.error("Failed to remove favorite: \(error)")
            self.error = AppError.custom("Failed to remove favorite")
        }
    }
    
    func speakAffirmation(_ affirmation: Affirmation) {
        services?.speechManager.speak(
            affirmation.text,
            voice: VoiceProfile.defaultVoiceProfile
        )
    }
    
    // MARK: - Mock Data
    private func loadMockFavorites() {
        favorites = MockDataProvider.shared.mockFavorites
        isLoading = false
    }
}
