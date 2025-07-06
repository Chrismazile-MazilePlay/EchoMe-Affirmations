//
//  SignUpView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSignUp: (String, String, String?) async throws -> Void
    let onSignInTap: () -> Void
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            // Title
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start your affirmation journey")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Form
            VStack(spacing: 16) {
                TextField("Name (optional)", text: $name)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.name)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.newPassword)
                
                if !password.isEmpty && password != confirmPassword {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Sign Up Button
            Button {
                Task {
                    await signUp()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || !isFormValid)
            
            // Sign In Link
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.secondary)
                Button("Sign In") {
                    onSignInTap()
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
    
    private func signUp() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await onSignUp(email, password, name.isEmpty ? nil : name)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SignUpView(
        onSignUp: { _, _, _ in
            try await Task.sleep(nanoseconds: 1_000_000_000)
        },
        onSignInTap: {
            print("Sign in tapped")
        }
    )
}
