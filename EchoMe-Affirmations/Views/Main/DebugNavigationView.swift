//
//  DebugNavigationView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct DebugNavigationView: View {
    @Environment(\.services) private var services
    
    private var nav: NavigationState { services.navigationState }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Debug Navigation")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Authenticated: \(nav.isAuthenticated ? "✅" : "❌")")
                Text("Onboarded: \(nav.hasCompletedOnboarding ? "✅" : "❌")")
                Text("Current View: \(String(describing: nav.currentView))")
                Text("User ID: \(nav.userId.isEmpty ? "None" : nav.userId)")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Debug buttons
            Button("Toggle Auth") {
                if nav.isAuthenticated {
                    nav.signOut()
                } else {
                    nav.setAuthenticated(userId: "debug-user")
                }
            }
            
            Button("Toggle Onboarding") {
                nav.hasCompletedOnboarding.toggle()
            }
            
            Button("Reset All") {
                nav.reset()
            }
        }
        .padding()
    }
}
