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
    @State private var authVM: AuthenticationViewModel?
    
    var body: some View {
        Group {
            if let authVM = authVM {
                switch authVM.authState {
                case .signedOut:
                    NavigationStack {
                        if showSignUp {
                            SignUpView(
                                onSignUp: { email, password, name in
                                    try await authVM.signUp(
                                        email: email,
                                        password: password,
                                        name: name
                                    )
                                },
                                onSignInTap: {
                                    showSignUp = false
                                },
                                passwordError: authVM.passwordError
                            )
                        } else {
                            SignInView(
                                onSignIn: { email, password in
                                    try await authVM.signIn(
                                        email: email,
                                        password: password
                                    )
                                },
                                onSignUpTap: {
                                    showSignUp = true
                                }
                            )
                        }
                    }
                    
                case .loading:
                    ProgressView()
                        .scaleEffect(1.5)
                    
                case .signedIn(let user):
                    if user.hasCompletedOnboarding {
                        ContentView()
                    } else {
                        OnboardingView()
                    }
                }
            } else {
                ProgressView()
                    .onAppear {
                        print("🟧 RootView: Getting AuthViewModel")
                        authVM = services.authViewModel
                        print("🟧 RootView: AuthViewModel retrieved")
                    }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(\.services, ServicesContainer.preview)
}
