//
//  AuthManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

//
//  AuthManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
public class AuthenticationManager {
    // MARK: - Properties
    var currentUser: AuthUser?
    var userProfile: User?
    var isLoading = false
    var errorMessage: String?
    
    // Navigation state reference
    weak var navigationState: NavigationState?
    
    // MARK: - Private Properties
    private let firebaseService: FirebaseService
    private var userProfileListener: FirebaseListener?
    private let isPreview: Bool
    
    // MARK: - Initialization
    public init(firebaseService: FirebaseService? = nil, isPreview: Bool = false) {
        self.firebaseService = firebaseService ?? FirebaseService.shared
        self.isPreview = isPreview
        
        if !isPreview && !MockDataProvider.isPreview {
            Task {
                await setupAuthStateListener()
            }
        }
    }
    
    // MARK: - Preview Support
    static let preview: AuthenticationManager = {
        let manager = AuthenticationManager(isPreview: true)
        manager.userProfile = User(
            id: "preview-user",
            email: "preview@example.com",
            displayName: "Preview User",
            preferences: UserPreferences(categories: ["motivation", "confidence"])
        )
        return manager
    }()
    
    // MARK: - Cleanup
    func cleanup() {
        if let listener = userProfileListener {
            firebaseService.removeListener(listener)
            userProfileListener = nil
        }
    }
    
    // MARK: - Auth State Management
    private func setupAuthStateListener() async {
        firebaseService.startAuthStateListener { [weak self] authUser in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.currentUser = authUser
                
                if let authUser = authUser {
                    // User is authenticated - update navigation state instantly
                    self.navigationState?.setAuthenticated(userId: authUser.uid)
                    await self.listenToUserProfile(userId: authUser.uid)
                } else {
                    // User signed out - clear everything instantly
                    self.navigationState?.signOut()
                    if let listener = self.userProfileListener {
                        self.firebaseService.removeListener(listener)
                        self.userProfileListener = nil
                    }
                    self.userProfile = nil
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    private func listenToUserProfile(userId: String) async {
        guard !isPreview else {
            navigationState?.setOnboardingCompleted()
            return
        }
        
        userProfileListener = firebaseService.listenToUserProfile(userId: userId) { [weak self] profileData in
            Task { @MainActor in
                guard let self = self, let profileData = profileData else { return }
                
                // Update onboarding status instantly in navigation state
                if profileData.onboardingCompleted {
                    self.navigationState?.setOnboardingCompleted()
                }
                
                // Parse preferences
                let preferencesData = profileData.preferences
                let preferences = UserPreferences(
                    categories: preferencesData["categories"] as? [String] ?? [],
                    voiceProfile: preferencesData["voiceProfile"] as? String ?? "Calm & Clear",
                    dailyAffirmationCount: preferencesData["dailyAffirmationCount"] as? Int ?? 5,
                    notificationEnabled: preferencesData["notificationEnabled"] as? Bool ?? false,
                    notificationTime: nil, // Handle date parsing as needed
                    theme: AppTheme(rawValue: preferencesData["theme"] as? String ?? "system") ?? .system
                )
                
                // Create custom User model
                self.userProfile = User(
                    id: userId,
                    email: profileData.email,
                    displayName: profileData.displayName,
                    preferences: preferences,
                    createdAt: profileData.createdAt,
                    lastActiveAt: profileData.lastActiveAt,
                    totalAffirmationsViewed: profileData.totalAffirmationsViewed,
                    favoriteCount: profileData.favoriteCount,
                    currentStreak: profileData.currentStreak,
                    longestStreak: profileData.longestStreak
                )
            }
        }
    }
    
    // MARK: - Authentication Methods
    func signIn(email: String, password: String) async throws {
        guard !isPreview else {
            navigationState?.setAuthenticated(userId: "preview-user")
            navigationState?.setOnboardingCompleted()
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
            let authUser = try await firebaseService.signIn(email: email, password: password)
            
            // Update last active
            try await firebaseService.updateUserData(
                userId: authUser.uid,
                updates: ["lastActiveAt": Date()]
            )
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        guard !isPreview else {
            navigationState?.setAuthenticated(userId: "preview-user")
            userProfile = User(
                id: "preview-user",
                email: email
            )
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let authUser = try await firebaseService.signUp(email: email, password: password)
            
            // Create user profile
            try await firebaseService.createUserProfile(userId: authUser.uid, email: email)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() {
        guard !isPreview else {
            navigationState?.signOut()
            userProfile = nil
            return
        }
        
        do {
            try firebaseService.signOut()
            // Navigation state will be updated by auth state listener
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - Update Methods
    func completeOnboarding(categories: [String]) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notConfigured
        }
        
        guard !isPreview else {
            navigationState?.setOnboardingCompleted()
            return
        }
        
        try await firebaseService.updateUserData(
            userId: userId,
            updates: [
                "onboardingCompleted": true,
                "preferences.categories": categories
            ]
        )
        
        // Update navigation state instantly
        navigationState?.setOnboardingCompleted()
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notConfigured
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
            "preferences.theme": preferences.theme.rawValue
        ]
        
        try await firebaseService.updateUserData(userId: userId, updates: preferencesData)
    }
    
    func updateDisplayName(_ displayName: String) async throws {
        guard let userId = currentUser?.uid else {
            throw FirebaseError.notConfigured
        }
        
        guard !isPreview else {
            userProfile?.displayName = displayName
            return
        }
        
        try await firebaseService.updateUserData(
            userId: userId,
            updates: ["displayName": displayName]
        )
    }
    
    func trackAffirmationViewed() async {
        guard let userId = currentUser?.uid, !isPreview else { return }
        
        try? await firebaseService.incrementUserStat(
            userId: userId,
            field: "totalAffirmationsViewed"
        )
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        guard !isPreview else { return }
        
        try await firebaseService.resetPassword(email: email)
    }
}

// MARK: - Preview Helpers
extension AuthenticationManager {
    /// Creates a preview instance for specific authentication states
    static func preview(isAuthenticated: Bool, hasCompletedOnboarding: Bool) -> AuthenticationManager {
        let manager = AuthenticationManager(isPreview: true)
        let navState = NavigationState()
        manager.navigationState = navState
        
        if isAuthenticated {
            navState.setAuthenticated(userId: "preview-user")
            if hasCompletedOnboarding {
                navState.setOnboardingCompleted()
            }
            
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
