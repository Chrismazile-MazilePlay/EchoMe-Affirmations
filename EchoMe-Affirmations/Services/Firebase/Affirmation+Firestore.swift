//
//  Affirmation+Firestore.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation

extension Affirmation {
    // Convert from Firebase data
    static func from(data: [String: Any]) -> Affirmation? {
        guard let id = data["id"] as? String,
              let text = data["text"] as? String else { return nil }
        
        return Affirmation(
            id: id,
            text: text,
            categories: data["categories"] as? [String] ?? [],
            tone: data["tone"] as? String ?? "gentle",
            length: data["length"] as? String ?? "short",
            isActive: data["isActive"] as? Bool ?? true,
            createdAt: nil
        )
    }
    
    // Fetch methods using FirebaseService
    @MainActor
    static func fetchByCategories(_ categories: [String], limit: Int, firebaseService: FirebaseService? = nil) async throws -> [Affirmation] {
        let service = firebaseService ?? FirebaseService.shared
        let data = try await service.fetchAffirmations(categories: categories, limit: limit)
        return data.compactMap { Affirmation.from(data: $0) }
    }
    
    @MainActor
    static func fetchRandom(limit: Int, firebaseService: FirebaseService? = nil) async throws -> [Affirmation] {
        let service = firebaseService ?? FirebaseService.shared
        let data = try await service.fetchAffirmations(categories: nil, limit: limit)
        return data.compactMap { Affirmation.from(data: $0) }
    }
}
