//
//  AuthenticationView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(\.services) private var services
    private var authManager: AuthenticationManager { services.authManager }
    
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 50)
                
                Text("EchoMe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Form fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if isSignUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Action button
                Button(action: authenticate) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        }
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || authManager.isLoading)
                .padding(.horizontal)
                
                // Toggle auth mode
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top)
                
                Spacer()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(authManager.errorMessage ?? "An error occurred")
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && (!isSignUp || password == confirmPassword)
    }
    
    private func authenticate() {
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                showError = true
            }
        }
    }
}

#Preview("Sign In") {
    AuthenticationView()
        .environment(\.services, ServicesContainer.previewUnauthenticated)
}

#Preview("Sign Up") {
    AuthenticationView()
        .environment(\.services, ServicesContainer.previewUnauthenticated)
}
