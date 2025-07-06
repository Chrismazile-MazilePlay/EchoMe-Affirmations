//
//  FirebaseService.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

final class FirebaseService: FirebaseServiceProtocol {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    // Auth State
    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> String {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user.uid
    }
    
    func signUp(email: String, password: String) async throws -> String {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user.uid
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Affirmations
    
    func fetchAffirmations() async throws -> [[String: Any]] {
        let snapshot = try await db.collection("affirmations").getDocuments()
        return snapshot.documents.map { $0.data() }
    }
    
    // MARK: - Favorites
    
    func addFavorite(userId: String, affirmationId: String, text: String) async throws {
        try await db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
            .setData([
                "affirmationId": affirmationId,
                "text": text,
                "savedAt": Timestamp(date: Date())
            ])
    }
    
    func removeFavorite(userId: String, affirmationId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
            .delete()
    }
    
    func listenToFavorites(userId: String, completion: @escaping ([String]) -> Void) -> String {
        let listenerKey = UUID().uuidString
        let listener = db.collection("users").document(userId)
            .collection("favorites")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let favoriteIds = documents.map { $0.documentID }
                completion(favoriteIds)
            }
        listeners[listenerKey] = listener
        return listenerKey
    }
    
    func removeListener(_ key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
    }
}
