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
            NavigationStack {
                if showSignUp {
                    SignUpView(
                        onSignUp: { email, password, name in
                            try await services.authViewModel.signUp(
                                email: email,
                                password: password,
                                name: name
                            )
                        },
                        onSignInTap: {
                            showSignUp = false
                        }
                    )
                } else {
                    SignInView(
                        onSignIn: { email, password in
                            try await services.authViewModel.signIn(
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
    }
}

#Preview {
    RootView()
        .environment(\.services, ServicesContainer.preview)
}
