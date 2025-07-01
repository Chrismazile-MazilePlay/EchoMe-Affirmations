//
//  AuthManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation
import SwiftUI

@Observable
@MainActor
class AuthenticationManager {
    // MARK: - Properties
    var isAuthenticated = false
    var hasCompletedOnboarding = false
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var userProfileListener: ListenerRegistration?
    
    // MARK: - Singleton
    static let shared = AuthenticationManager()
    
    // MARK: - Preview Support
    static let preview: AuthenticationManager = {
        let manager = AuthenticationManager(isPreview: true)
        manager.isAuthenticated = true
        manager.hasCompletedOnboarding = true
        return manager
    }()
    
    private let isPreview: Bool
    
    // MARK: - Initialization
    private init(isPreview: Bool = false) {
        self.isPreview = isPreview
        
        // Only setup Firebase listeners if not in preview
        if !isPreview && !MockDataProvider.isPreview {
            setupAuthStateListener()
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
        userProfileListener?.remove()
        userProfileListener = nil
    }
    
    // MARK: - Auth State Management
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.currentUser = user
                
                if let user = user {
                    await self?.listenToUserProfile(userId: user.uid)
                } else {
                    self?.userProfileListener?.remove()
                    self?.hasCompletedOnboarding = false
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    private func listenToUserProfile(userId: String) async {
        guard !isPreview else { return }
        
        userProfileListener?.remove()
        
        let db = Firestore.firestore()
        userProfileListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let data = snapshot?.data(),
                       let completed = data["onboardingCompleted"] as? Bool {
                        self?.hasCompletedOnboarding = completed
                    }
                }
            }
    }
    
    // MARK: - Authentication Methods
    func signIn(email: String, password: String) async throws {
        guard !isPreview else {
            // Simulate success in preview
            isAuthenticated = true
            hasCompletedOnboarding = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        guard !isPreview else {
            // Simulate success in preview
            isAuthenticated = true
            hasCompletedOnboarding = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile
            try await createUserProfile(for: result.user, email: email)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() {
        guard !isPreview else {
            isAuthenticated = false
            hasCompletedOnboarding = false
            return
        }
        
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - User Profile Creation
    private func createUserProfile(for user: User, email: String) async throws {
        guard !isPreview else { return }
        
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Date(),
            "onboardingCompleted": false,
            "preferences": [
                "categories": [],
                "preferredTone": "gentle",
                "dailyAffirmationCount": 5
            ]
        ]
        
        let db = Firestore.firestore()
        try await db.collection("users").document(user.uid).setData(userData)
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        guard !isPreview else {
            // Simulate success in preview
            return
        }
        
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}

// MARK: - Preview Helpers
extension AuthenticationManager {
    /// Creates a preview instance for specific authentication states
    static func preview(isAuthenticated: Bool, hasCompletedOnboarding: Bool) -> AuthenticationManager {
        let manager = AuthenticationManager(isPreview: true)
        manager.isAuthenticated = isAuthenticated
        manager.hasCompletedOnboarding = hasCompletedOnboarding
        return manager
    }
    
    /// Preview instance for unauthenticated state
    static let previewUnauthenticated = preview(isAuthenticated: false, hasCompletedOnboarding: false)
    
    /// Preview instance for authenticated but not onboarded
    static let previewNeedsOnboarding = preview(isAuthenticated: true, hasCompletedOnboarding: false)
    
    /// Preview instance for fully authenticated and onboarded
    static let previewAuthenticated = preview(isAuthenticated: true, hasCompletedOnboarding: true)
}

#Preview("Auth States", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        Text("Authenticated: \(AuthenticationManager.preview.isAuthenticated ? "Yes" : "No")")
        Text("Onboarded: \(AuthenticationManager.preview.hasCompletedOnboarding ? "Yes" : "No")")
        
        Button("Toggle Auth") {
            AuthenticationManager.preview.isAuthenticated.toggle()
        }
    }
    .environment(AuthenticationManager.preview)
}
