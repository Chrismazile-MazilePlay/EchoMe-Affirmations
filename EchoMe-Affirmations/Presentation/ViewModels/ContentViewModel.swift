//
//  ContentViewModel.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class ContentViewModel {
    var affirmations: [Affirmation] = []
    var favoriteIds: Set<String> = []
    var isLoading = false
    
    private let mockDataProvider: MockDataProvider
    
    init(mockDataProvider: MockDataProvider) {
        self.mockDataProvider = mockDataProvider
    }
    
    func loadAffirmations() {
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            affirmations = mockDataProvider.getAllAffirmations()
            isLoading = false
        }
    }
    
    func toggleFavorite(for affirmation: Affirmation) {
        if favoriteIds.contains(affirmation.id) {
            favoriteIds.remove(affirmation.id)
        } else {
            favoriteIds.insert(affirmation.id)
        }
    }
    
    func isFavorite(_ affirmationId: String) -> Bool {
        favoriteIds.contains(affirmationId)
    }
    
    func playAffirmation(_ affirmation: Affirmation) {
        print("Playing: \(affirmation.text)")
        // TODO: Integrate with SpeechManager
    }
    
    func shareAffirmation(_ affirmation: Affirmation) {
        print("Sharing: \(affirmation.text)")
        // TODO: Implement share functionality
    }
}
