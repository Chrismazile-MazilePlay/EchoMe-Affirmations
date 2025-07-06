//
//  AuthenticationRepository.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import Combine

final class AuthenticationRepository: AuthenticationRepositoryProtocol, ServiceProtocol {
    private let firebaseService: FirebaseServiceProtocol
    private let authStateSubject = CurrentValueSubject<AuthState, Never>(.signedOut)
    private var isSetup = false
    
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    var isReady: Bool { isSetup }
    
    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }
    
    func setup() async throws {
        // Check current auth state
        if let user = getCurrentUser() {
            authStateSubject.send(.signedIn(user))
        }
        isSetup = true
    }
    
    func signIn(email: String, password: String) async throws -> User {
        authStateSubject.send(.loading)
        let userId = try await firebaseService.signIn(email: email, password: password)
        let user = User(id: userId, email: email)
        authStateSubject.send(.signedIn(user))
        return user
    }
    
    func signUp(email: String, password: String, name: String?) async throws -> User {
        authStateSubject.send(.loading)
        let userId = try await firebaseService.signUp(email: email, password: password)
        let user = User(id: userId, email: email, name: name)
        authStateSubject.send(.signedIn(user))
        return user
    }
    
    func signOut() async throws {
        try firebaseService.signOut()
        authStateSubject.send(.signedOut)
    }
    
    func resetPassword(email: String) async throws {
        // TODO: Implement password reset
    }
    
    func deleteAccount() async throws {
        // TODO: Implement account deletion
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = firebaseService.currentUser else { return nil }
        return User(id: firebaseUser.uid, email: firebaseUser.email ?? "")
    }
}
