//
//  RootView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct RootView: View {
    @Environment(\.services) private var services
    @State private var showSignUp = false
    
    var body: some View {
        switch services.authViewModel.authState {
        case .signedOut:
            authenticationFlow
            
        case .loading:
            loadingView
            
        case .signedIn(let user):
            authenticatedView(for: user)
        }
    }
    
    // MARK: - View Components
    
    private var authenticationFlow: some View {
        NavigationStack {
            if showSignUp {
                signUpView
            } else {
                signInView
            }
        }
    }
    
    private var signUpView: some View {
        SignUpView(
            onSignUp: handleSignUp,
            onSignInTap: { showSignUp = false },
            passwordError: services.authViewModel.passwordError
        )
    }
    
    private var signInView: some View {
        SignInView(
            onSignIn: handleSignIn,
            onSignUpTap: { showSignUp = true }
        )
    }
    
    private var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
    }
    
    // MARK: - Helper Functions
    
    private func authenticatedView(for user: User) -> some View {
        Group {
            if user.hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
    
    private func handleSignUp(email: String, password: String, name: String?) async throws {
        try await services.authViewModel.signUp(
            email: email,
            password: password,
            name: name
        )
    }
    
    private func handleSignIn(email: String, password: String) async throws {
        try await services.authViewModel.signIn(
            email: email,
            password: password
        )
    }
}

#Preview {
    RootView()
        .environment(\.services, ServicesContainer.preview)
}
