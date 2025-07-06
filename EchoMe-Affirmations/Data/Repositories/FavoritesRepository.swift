//
//  FavoritesRepository.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

//
//  FavoritesRepository.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 01/05/25.
//

import Foundation
import Combine

final class FavoritesRepository: FavoritesRepositoryProtocol, ServiceProtocol {
    private let firebaseService: FirebaseServiceProtocol
    private let favoriteIdsSubject = CurrentValueSubject<Set<String>, Never>([])
    private var listenerKey: String?
    private var isSetup = false
    
    var favoriteIdsPublisher: AnyPublisher<Set<String>, Never> {
        favoriteIdsSubject.eraseToAnyPublisher()
    }
    
    var isReady: Bool { isSetup }
    
    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }
    
    func setup() async throws {
        startListening()
        isSetup = true
    }
    
    func cleanup() {
        stopListening()
        isSetup = false
    }
    
    private func startListening() {
        guard let userId = firebaseService.currentUser?.uid else { return }
        
        listenerKey = firebaseService.listenToFavorites(userId: userId) { [weak self] favoriteIds in
            self?.favoriteIdsSubject.send(Set(favoriteIds))
        }
    }
    
    private func stopListening() {
        if let key = listenerKey {
            firebaseService.removeListener(key)
            listenerKey = nil
        }
    }
    
    func addFavorite(affirmationId: String, text: String) async throws {
        guard let userId = firebaseService.currentUser?.uid else { return }
        try await firebaseService.addFavorite(userId: userId, affirmationId: affirmationId, text: text)
    }
    
    func removeFavorite(affirmationId: String) async throws {
        guard let userId = firebaseService.currentUser?.uid else { return }
        try await firebaseService.removeFavorite(userId: userId, affirmationId: affirmationId)
    }
    
    func isFavorite(affirmationId: String) -> Bool {
        favoriteIdsSubject.value.contains(affirmationId)
    }
    
    func getFavoriteIds() -> Set<String> {
        favoriteIdsSubject.value
    }
    
    func syncWithWatch(favoriteIds: [String]) async throws {
        // TODO: Implement Watch sync
    }
}
