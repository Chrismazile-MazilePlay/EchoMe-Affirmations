//
//  EchoMe_AffirmationsApp.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI
import FirebaseCore

@main
struct EchoMeApp: App {
    @State private var authManager: AuthenticationManager
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Configure Firebase FIRST
        FirebaseApp.configure()
        
        // Then create AuthenticationManager
        self._authManager = State(initialValue: AuthenticationManager.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    if authManager.hasCompletedOnboarding {
                        NavigationStack {
                            ContentView()
                        }
                    } else {
                        OnboardingView()
                    }
                } else {
                    AuthenticationView()
                }
            }
            .animation(.easeInOut, value: authManager.isAuthenticated)
            .animation(.easeInOut, value: authManager.hasCompletedOnboarding)
            .environment(authManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                authManager.cleanup()
            }
        }
    }
}
