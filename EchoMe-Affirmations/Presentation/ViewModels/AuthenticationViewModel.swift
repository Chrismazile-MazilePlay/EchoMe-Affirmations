//
//  AuthenticationViewModel.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import Observation

@Observable
final class AuthenticationViewModel {
    var authState: AuthState = .signedOut
    var currentUser: User?
    
    func signIn(email: String, password: String) async throws {
        authState = .loading
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create mock user
        let user = User(
            email: email,
            name: "Test User",
            hasCompletedOnboarding: false
        )
        
        currentUser = user
        authState = .signedIn(user)
    }
    
    func signUp(email: String, password: String, name: String?) async throws {
        authState = .loading
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create new user
        let user = User(
            email: email,
            name: name,
            hasCompletedOnboarding: false
        )
        
        currentUser = user
        authState = .signedIn(user)
    }
    
    func signOut() async throws {
        authState = .loading
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        currentUser = nil
        authState = .signedOut
    }
}
