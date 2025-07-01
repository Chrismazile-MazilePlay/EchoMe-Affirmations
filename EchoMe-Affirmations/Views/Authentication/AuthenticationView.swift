//
//  AuthenticationView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingResetPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("EchoMe")
                .font(.largeTitle)
                .bold()
            
            Text(isSignUp ? "Create Account" : "Sign In")
                .font(.title2)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: authenticate) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(isSignUp ? "Create Account" : "Sign In")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
            
            VStack(spacing: 15) {
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                if !isSignUp {
                    Button(action: { showingResetPassword = true }) {
                        Text("Forgot Password?")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView()
        }
    }
    
    func authenticate() {
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                // Error is handled by authManager
            }
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .padding(.top)
                
                Text("Enter your email and we'll send you a reset link")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("sent") ? .green : .red)
                }
                
                Button(action: resetPassword) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || email.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func resetPassword() {
        isLoading = true
        Task {
            do {
                try await AuthenticationManager.shared.resetPassword(email: email)
                message = "Reset link sent to \(email)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } catch {
                message = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview("Sign In") {
    AuthenticationView()
        .environment(AuthenticationManager.previewUnauthenticated)
} 
