//
//  ContentViewModel.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class ContentViewModel: @preconcurrency ErrorHandling {
    // MARK: - Published Properties
    var affirmations: [Affirmation] = []
    var currentIndex = 0
    var userCategories: [String] = []
    var isOffline = false
    var hasInitiallyLoaded = false
    var error: AppError?  // Added for ErrorHandling protocol
    
    // MARK: - Dependencies
    private var services: ServicesContainer?
    
    // MARK: - Initialization
    func setup(with services: ServicesContainer) {
        self.services = services
        
        loadUserPreferences()
        
        // Try to load from cache first
        if loadCachedAffirmations() {
            services.favoritesManager.startListening()
        } else {
            services.favoritesManager.startListening()
            Task {
                await loadAffirmations()
            }
        }
        
        hasInitiallyLoaded = true
    }
    
    // MARK: - Public Methods
    func onAppear() {
        guard let services = services else { return }
        
        if !hasInitiallyLoaded {
            setup(with: services)
        } else {
            services.favoritesManager.startListening()
        }
    }
    
    func onDisappear() {
        services?.favoritesManager.stopListening()
    }
    
    // MARK: - Private Methods
    private func loadUserPreferences() {
        if let preferences = services?.authManager.userProfile?.preferences {
            userCategories = preferences.categories
        }
    }
    
    private func loadCachedAffirmations() -> Bool {
        guard let services = services else { return false }
        
        if !services.affirmationCacheManager.currentBatch.isEmpty {
            affirmations = services.affirmationCacheManager.currentBatch
            sendAffirmationsToWatch()
            return true
        }
        return false
    }
    
    func loadAffirmations(forceRefresh: Bool = false) async {
        guard let services = services else {
            Logger.error("Services not available")
            return
        }
        
        Logger.debug("Loading affirmations (forceRefresh: \(forceRefresh))")
        
        if MockDataProvider.isPreview {
            await MainActor.run {
                self.affirmations = MockDataProvider.shared.getDailyAffirmations()
                sendAffirmationsToWatch()
            }
            return
        }
        
        do {
            await services.affirmationCacheManager.loadBatch(
                categories: userCategories,
                forceRefresh: forceRefresh
            )
            
            await MainActor.run {
                self.affirmations = services.affirmationCacheManager.currentBatch
                self.isOffline = false
                
                if !affirmations.isEmpty {
                    Logger.success("Loaded \(affirmations.count) affirmations")
                    sendAffirmationsToWatch()
                } else {
                    Logger.warning("No affirmations loaded")
                }
            }
        } catch {
            handleError(error)
            self.isOffline = true
        }
    }
    
    private func sendAffirmationsToWatch() {
        guard let services = services else { return }
        Logger.info("Sending \(affirmations.count) affirmations to watch")
        services.watchConnectivityManager.sendAffirmationsToWatch(affirmations)
    }
    
    // MARK: - More Public Methods
    func checkForMoreAffirmations(at index: Int) {
        guard let services = services else { return }
        
        currentIndex = index
        
        Task {
            await services.affirmationCacheManager.checkAndLoadMore(
                currentIndex: index,
                categories: userCategories
            )
            
            await MainActor.run {
                let newBatch = services.affirmationCacheManager.currentBatch
                if newBatch.count > affirmations.count {
                    affirmations = newBatch
                } else if index >= affirmations.count - 1 {
                    isOffline = true
                }
            }
        }
    }
    
    func toggleFavorite(_ affirmation: Affirmation) {
        guard let services = services else { return }
        
        services.favoritesManager.toggleFavoriteOptimistic(
            affirmationId: affirmation.id,
            affirmationText: affirmation.text
        )
    }
    
    func isFavorite(_ affirmationId: String) -> Bool {
        return services?.favoritesManager.isFavorite(affirmationId) ?? false
    }
}
