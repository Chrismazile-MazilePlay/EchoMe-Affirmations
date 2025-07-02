//
//  NavigationState.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI
import Observation

@Observable
@MainActor
class NavigationState {
    var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
        }
    }
    
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    var userId: String {
        didSet {
            UserDefaults.standard.set(userId, forKey: "userId")
        }
    }
    
    // Computed property for current view
    var currentView: AppView {
        if !isAuthenticated {
            return .authentication
        } else if !hasCompletedOnboarding {
            return .onboarding
        } else {
            return .main
        }
    }
    
    enum AppView {
        case authentication
        case onboarding
        case main
    }
    
    init() {
        // Load initial values from UserDefaults
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? ""
    }
    
    // Instant navigation methods
    func setAuthenticated(userId: String) {
        self.userId = userId
        self.isAuthenticated = true
    }
    
    func setOnboardingCompleted() {
        self.hasCompletedOnboarding = true
    }
    
    func signOut() {
        // Clear all states instantly
        self.isAuthenticated = false
        self.hasCompletedOnboarding = false
        self.userId = ""
    }
    
    func reset() {
        signOut()
    }
}
