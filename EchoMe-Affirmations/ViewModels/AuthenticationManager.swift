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
    var currentUser: FirebaseAuth.User?  // Firebase auth user
    var userProfile: User?  // Our custom user model
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
        manager.userProfile = User(
            id: "preview-user",
            email: "preview@example.com",
            displayName: "Preview User",
            preferences: UserPreferences(categories: ["motivation", "confidence"])
        )
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
                    self?.userProfile = nil
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
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error listening to user profile: \(error)")
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        self.hasCompletedOnboarding = false
                        self.userProfile = nil
                        return
                    }
                    
                    // Update onboarding status
                    self.hasCompletedOnboarding = data["onboardingCompleted"] as? Bool ?? false
                    
                    // Parse preferences
                    let preferencesData = data["preferences"] as? [String: Any] ?? [:]
                    let preferences = UserPreferences(
                        categories: preferencesData["categories"] as? [String] ?? [],
                        voiceProfile: preferencesData["voiceProfile"] as? String ?? "Calm & Clear",
                        dailyAffirmationCount: preferencesData["dailyAffirmationCount"] as? Int ?? 5,
                        notificationEnabled: preferencesData["notificationEnabled"] as? Bool ?? false,
                        notificationTime: (preferencesData["notificationTime"] as? Timestamp)?.dateValue(),
                        theme: AppTheme(rawValue: preferencesData["theme"] as? String ?? "system") ?? .system
                    )
                    
                    // Create custom User model
                    self.userProfile = User(
                        id: userId,
                        email: self.currentUser?.email ?? "",
                        displayName: data["displayName"] as? String,
                        preferences: preferences,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        lastActiveAt: (data["lastActiveAt"] as? Timestamp)?.dateValue(),
                        totalAffirmationsViewed: data["totalAffirmationsViewed"] as? Int ?? 0,
                        favoriteCount: data["favoriteCount"] as? Int ?? 0,
                        currentStreak: data["currentStreak"] as? Int ?? 0,
                        longestStreak: data["longestStreak"] as? Int ?? 0
                    )
                }
            }
    }
    
    // MARK: - Authentication Methods
    func signIn(email: String, password: String) async throws {
        guard !isPreview else {
            // Simulate success in preview
            isAuthenticated = true
            hasCompletedOnboarding = true
            userProfile = User(
                id: "preview-user",
                email: email,
                displayName: "Preview User"
            )
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Update last active timestamp
            try await updateLastActive(userId: result.user.uid)
            
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
            userProfile = User(
                id: "preview-user",
                email: email
            )
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
            userProfile = nil
            return
        }
        
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - User Profile Creation
    private func createUserProfile(for user: FirebaseAuth.User, email: String) async throws {
        guard !isPreview else { return }
        
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "onboardingCompleted": false,
            "preferences": [
                "categories": [],
                "voiceProfile": "Calm & Clear",
                "dailyAffirmationCount": 5,
                "notificationEnabled": false,
                "theme": "system"
            ],
            "totalAffirmationsViewed": 0,
            "favoriteCount": 0,
            "currentStreak": 0,
            "longestStreak": 0
        ]
        
        let db = Firestore.firestore()
        try await db.collection("users").document(user.uid).setData(userData)
    }
    
    // MARK: - Update Methods
    func completeOnboarding(categories: [String]) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        guard !isPreview else {
            hasCompletedOnboarding = true
            userProfile?.preferences.categories = categories
            return
        }
        
        let updates: [String: Any] = [
            "onboardingCompleted": true,
            "preferences.categories": categories,
            "lastActiveAt": Timestamp(date: Date())
        ]
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData(updates)
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        guard !isPreview else {
            userProfile?.preferences = preferences
            return
        }
        
        let preferencesData: [String: Any] = [
            "preferences.categories": preferences.categories,
            "preferences.voiceProfile": preferences.voiceProfile,
            "preferences.dailyAffirmationCount": preferences.dailyAffirmationCount,
            "preferences.notificationEnabled": preferences.notificationEnabled,
            "preferences.notificationTime": preferences.notificationTime != nil ? Timestamp(date: preferences.notificationTime!) : NSNull(),
            "preferences.theme": preferences.theme.rawValue,
            "lastActiveAt": Timestamp(date: Date())
        ]
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData(preferencesData)
    }
    
    func updateDisplayName(_ displayName: String) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        guard !isPreview else {
            userProfile?.displayName = displayName
            return
        }
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "displayName": displayName,
            "lastActiveAt": Timestamp(date: Date())
        ])
    }
    
    func incrementAffirmationCount() async throws {
        guard let userId = currentUser?.uid else { return }
        guard !isPreview else {
            userProfile?.totalAffirmationsViewed += 1
            return
        }
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "totalAffirmationsViewed": FieldValue.increment(Int64(1)),
            "lastActiveAt": Timestamp(date: Date())
        ])
    }
    
    private func updateLastActive(userId: String) async throws {
        guard !isPreview else { return }
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "lastActiveAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        guard !isPreview else { return }
        
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
        
        if isAuthenticated {
            manager.userProfile = User(
                id: "preview-user",
                email: "preview@example.com",
                displayName: "Preview User",
                preferences: UserPreferences(
                    categories: hasCompletedOnboarding ? ["motivation", "confidence"] : []
                )
            )
        }
        
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
        
        if let profile = AuthenticationManager.preview.userProfile {
            Text("User: \(profile.displayNameOrEmail)")
            Text("Member for: \(profile.membershipDuration)")
            Text("Categories: \(profile.preferences.categories.joined(separator: ", "))")
        }
        
        Button("Toggle Auth") {
            AuthenticationManager.preview.isAuthenticated.toggle()
        }
    }
    .environment(AuthenticationManager.preview)
}
