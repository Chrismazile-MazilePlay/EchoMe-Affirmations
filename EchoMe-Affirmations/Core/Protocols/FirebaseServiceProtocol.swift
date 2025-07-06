//
//  FirebaseServiceProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

//
//  FirebaseServiceProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 01/05/25.
//

import Foundation
import FirebaseAuth

protocol FirebaseServiceProtocol {
    var currentUser: FirebaseAuth.User? { get }
    
    // Authentication
    func signIn(email: String, password: String) async throws -> String
    func signUp(email: String, password: String) async throws -> String
    func signOut() throws
    
    // Affirmations
    func fetchAffirmations() async throws -> [[String: Any]]
    
    // Favorites
    func addFavorite(userId: String, affirmationId: String, text: String) async throws
    func removeFavorite(userId: String, affirmationId: String) async throws
    func listenToFavorites(userId: String, completion: @escaping ([String]) -> Void) -> String
    func removeListener(_ key: String)
}
