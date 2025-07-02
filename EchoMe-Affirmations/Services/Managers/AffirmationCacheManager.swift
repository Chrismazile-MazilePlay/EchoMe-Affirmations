//
//  AffirmationCacheManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AffirmationCacheManager {
    // MARK: - Properties
    private let modelContainer: ModelContainer?
    private let firebaseService: FirebaseService
    
    // Observable state
    var cachedAffirmations: [Affirmation] = []
    var isLoading = false
    var lastRefresh: Date?
    
    // MARK: - Constants
    private let cacheExpirationHours: Double = 24
    private let maxCachedItems = 50
    
    // MARK: - Initialization
    init(firebaseService: FirebaseService, isPreview: Bool = false) {
        self.firebaseService = firebaseService
        
        if !isPreview {
            do {
                self.modelContainer = try ModelContainer(for: CachedAffirmation.self)
                loadCachedAffirmations()
            } catch {
                print("❌ Failed to create ModelContainer: \(error)")
                self.modelContainer = nil
            }
        } else {
            self.modelContainer = nil
            loadMockData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load affirmations with cache-first strategy
    func loadAffirmations(categories: [String], forceRefresh: Bool = false) async {
        // Always show cached data immediately
        if !cachedAffirmations.isEmpty && !forceRefresh {
            print("📱 Using cached affirmations: \(cachedAffirmations.count)")
            return
        }
        
        // Refresh if cache is stale or forced
        if shouldRefreshCache() || forceRefresh {
            await refreshFromFirebase(categories: categories)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCachedAffirmations() {
        guard let modelContainer = modelContainer else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedAffirmation>(
                sortBy: [SortDescriptor(\.order)]
            )
            let context = ModelContext(modelContainer)
            let cached = try context.fetch(descriptor)
            
            self.cachedAffirmations = cached.map { $0.affirmation }
            self.lastRefresh = cached.first?.cachedAt
            
            print("📱 Loaded \(cached.count) cached affirmations")
        } catch {
            print("❌ Failed to load cache: \(error)")
        }
    }
    
    private func shouldRefreshCache() -> Bool {
        guard let lastRefresh = lastRefresh else { return true }
        let hoursSinceRefresh = Date().timeIntervalSince(lastRefresh) / 3600
        return hoursSinceRefresh > cacheExpirationHours
    }
    
    private func refreshFromFirebase(categories: [String]) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedData = try await firebaseService.fetchAffirmations(
                categories: categories.isEmpty ? nil : categories,
                limit: maxCachedItems
            )
            
            let affirmations = fetchedData.compactMap { data -> Affirmation? in
                guard let id = data["id"] as? String,
                      let text = data["text"] as? String else { return nil }
                
                return Affirmation(
                    id: id,
                    text: text,
                    categories: data["categories"] as? [String] ?? [],
                    tone: data["tone"] as? String,
                    length: data["length"] as? String
                )
            }
            
            // Update cache
            await updateCache(with: affirmations)
            
            // Update observable state
            self.cachedAffirmations = affirmations
            self.lastRefresh = Date()
            
            print("📱 Refreshed with \(affirmations.count) affirmations from Firebase")
        } catch {
            print("❌ Failed to refresh from Firebase: \(error)")
        }
    }
    
    private func updateCache(with affirmations: [Affirmation]) async {
        guard let modelContainer = modelContainer else { return }
        
        let context = ModelContext(modelContainer)
        
        // Clear old cache
        do {
            try context.delete(model: CachedAffirmation.self)
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
        
        // Add new items
        for (index, affirmation) in affirmations.enumerated() {
            let cached = CachedAffirmation(
                id: affirmation.id,
                text: affirmation.text,
                categories: affirmation.categories,
                tone: affirmation.tone,
                length: affirmation.length,
                order: index
            )
            context.insert(cached)
        }
        
        do {
            try context.save()
        } catch {
            print("❌ Failed to save cache: \(error)")
        }
    }
    
    private func loadMockData() {
        cachedAffirmations = MockDataProvider.shared.mockAffirmations
    }
}

// MARK: - Preview Support
extension AffirmationCacheManager {
    static var preview: AffirmationCacheManager {
        AffirmationCacheManager(firebaseService: FirebaseService.shared, isPreview: true)
    }
}
