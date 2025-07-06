//
//  MockFirebaseService.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import FirebaseAuth

final class MockFirebaseService: FirebaseServiceProtocol {
    var currentUser: FirebaseAuth.User? = nil
    private var mockFavorites: Set<String> = []
    
    func signIn(email: String, password: String) async throws -> String {
        return "mock-user-id"
    }
    
    func signUp(email: String, password: String) async throws -> String {
        return "mock-user-id"
    }
    
    func signOut() throws {
        currentUser = nil
    }
    
    func fetchAffirmations() async throws -> [[String: Any]] {
        return [
            ["id": "1", "text": "I am worthy of love and respect.", "categories": ["Self-Love"]],
            ["id": "2", "text": "Today is full of possibilities.", "categories": ["Motivation"]]
        ]
    }
    
    func addFavorite(userId: String, affirmationId: String, text: String) async throws {
        mockFavorites.insert(affirmationId)
    }
    
    func removeFavorite(userId: String, affirmationId: String) async throws {
        mockFavorites.remove(affirmationId)
    }
    
    func listenToFavorites(userId: String, completion: @escaping ([String]) -> Void) -> String {
        completion(Array(mockFavorites))
        return "mock-listener"
    }
    
    func removeListener(_ key: String) {
        // Mock implementation
    }
}
