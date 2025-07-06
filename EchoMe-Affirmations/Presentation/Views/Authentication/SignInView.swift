//
//  SignInView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSignIn: (String, String) async throws -> Void
    let onSignUpTap: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            // Title
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.password)
            }
            
            // Sign In Button
            Button {
                Task {
                    await signIn()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            // Sign Up Link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                Button("Sign Up") {
                    onSignUpTap()
                }
            }
            .font(.footnote)
            
            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signIn() async {
        print("🟦 SignInView: SignIn button tapped")
        isLoading = true
        defer {
            isLoading = false
            print("🟦 SignInView: Loading state cleared")
        }
        
        do {
            print("🟦 SignInView: Calling onSignIn with email: \(email)")
            try await onSignIn(email, password)
            print("🟦 SignInView: onSignIn completed successfully")
        } catch {
            print("🟦 SignInView: SignIn error: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SignInView(
        onSignIn: { _, _ in
            try await Task.sleep(nanoseconds: 1_000_000_000)
        },
        onSignUpTap: {
            print("Sign up tapped")
        }
    )
}
