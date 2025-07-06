//
//  AffirmationRepository.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

//
//  AffirmationRepository.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 01/05/25.
//

import Foundation
import SwiftData

final class AffirmationRepository: AffirmationRepositoryProtocol, ServiceProtocol {
    private let firebaseService: FirebaseServiceProtocol
    private let modelContext: ModelContext?
    
    init(firebaseService: FirebaseServiceProtocol, modelContext: ModelContext? = nil) {
        self.firebaseService = firebaseService
        self.modelContext = modelContext
    }
    
    func setup() async throws {
        // Cache initial affirmations if needed
    }
    
    func fetchAffirmations() async throws -> [Affirmation] {
        let data = try await firebaseService.fetchAffirmations()
        return data.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let text = dict["text"] as? String else { return nil }
            
            return Affirmation(
                id: id,
                text: text,
                categories: dict["categories"] as? [String] ?? [],
                tone: dict["tone"] as? String,
                length: dict["length"] as? String
            )
        }
    }
    
    func fetchAffirmation(id: String) async throws -> Affirmation? {
        // TODO: Implement single affirmation fetch
        return nil
    }
    
    func fetchAffirmationsByCategory(_ category: String) async throws -> [Affirmation] {
        let all = try await fetchAffirmations()
        return all.filter { $0.categories.contains(category) }
    }
    
    func searchAffirmations(query: String) async throws -> [Affirmation] {
        let all = try await fetchAffirmations()
        return all.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }
    
    func cacheAffirmations(_ affirmations: [Affirmation]) async throws {
        guard let modelContext = modelContext else { return }
        
        for affirmation in affirmations {
            let cache = AffirmationCache(
                id: affirmation.id,
                text: affirmation.text,
                categories: affirmation.categories,
                tone: affirmation.tone,
                length: affirmation.length
            )
            modelContext.insert(cache)
        }
        
        try modelContext.save()
    }
    
    func getCachedAffirmations() async throws -> [Affirmation] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<AffirmationCache>()
        let cached = try modelContext.fetch(descriptor)
        
        return cached.map { cache in
            Affirmation(
                id: cache.id,
                text: cache.text,
                categories: cache.categories,
                tone: cache.tone,
                length: cache.length
            )
        }
    }
}
