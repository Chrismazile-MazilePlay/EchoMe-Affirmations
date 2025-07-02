//
//  ServicesContainer.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

@Observable
@MainActor
class ServicesContainer {
    let firebaseService: FirebaseService
    let navigationState: NavigationState
    let authManager: AuthenticationManager
    let favoritesManager: FavoritesManager
    let watchConnectivityManager: WatchConnectivityManager
    let speechManager: SpeechManager
    
    init(
        firebaseService: FirebaseService? = nil,
        navigationState: NavigationState? = nil,
        authManager: AuthenticationManager? = nil,
        favoritesManager: FavoritesManager? = nil,
        watchConnectivityManager: WatchConnectivityManager? = nil,
        speechManager: SpeechManager? = nil
    ) {
        // Create shared Firebase service
        self.firebaseService = firebaseService ?? FirebaseService()
        
        // Configure Firebase
        self.firebaseService.configure()
        
        // Create services with shared Firebase service
        self.navigationState = navigationState ?? NavigationState()
        self.authManager = authManager ?? AuthenticationManager(firebaseService: self.firebaseService)
        self.favoritesManager = favoritesManager ?? FavoritesManager(firebaseService: self.firebaseService)
        self.watchConnectivityManager = watchConnectivityManager ?? WatchConnectivityManager()
        self.speechManager = speechManager ?? SpeechManager()
        
        // Set up dependencies
        self.authManager.navigationState = self.navigationState
        self.favoritesManager.watchConnectivityManager = self.watchConnectivityManager
    }
    
    deinit {
        // Clean up Firebase listeners
        firebaseService.cleanup()
    }
}

// MARK: - Environment Key
private struct ServicesContainerKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = ServicesContainer()
}

extension EnvironmentValues {
    var services: ServicesContainer {
        get { self[ServicesContainerKey.self] }
        set { self[ServicesContainerKey.self] = newValue }
    }
}

// MARK: - Preview Helpers
extension ServicesContainer {
    @MainActor
    static var preview: ServicesContainer {
        let navState = NavigationState()
        navState.setAuthenticated(userId: "preview-user")
        navState.setOnboardingCompleted()
        
        return ServicesContainer(
            navigationState: navState,
            authManager: AuthenticationManager.previewAuthenticated
        )
    }
    
    @MainActor
    static var previewWithMockData: ServicesContainer {
        let container = preview
        container.favoritesManager.favoriteIds = ["mock1", "mock2", "mock3"]
        return container
    }
    
    @MainActor
    static var previewNeedsOnboarding: ServicesContainer {
        let navState = NavigationState()
        navState.setAuthenticated(userId: "preview-user")
        // Don't set onboarding completed
        
        return ServicesContainer(
            navigationState: navState,
            authManager: AuthenticationManager.previewNeedsOnboarding
        )
    }
    
    @MainActor
    static var previewUnauthenticated: ServicesContainer {
        ServicesContainer(
            navigationState: NavigationState(),
            authManager: AuthenticationManager.previewUnauthenticated
        )
    }
}
