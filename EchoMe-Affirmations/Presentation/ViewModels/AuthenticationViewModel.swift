//
//  AuthenticationViewModel.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import Observation
import Combine

@Observable
final class AuthenticationViewModel {
    var authState: AuthState = .signedOut
    var currentUser: User?
    var passwordError: String?
    
    private let authRepository: AuthenticationRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthenticationRepositoryProtocol) {
        print("🟨 AuthViewModel: Init ONCE with repository: \(type(of: authRepository))")
        self.authRepository = authRepository
        observeAuthState()
        
        // Check initial auth state
        Task {
            await checkAuthStatus()
        }
    }
    
    private func observeAuthState() {
        authRepository.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                print("🟨 AuthViewModel: State update received: \(state)")
                self?.authState = state
                if case .signedIn(let user) = state {
                    self?.currentUser = user
                } else {
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func validatePassword(_ password: String) -> Bool {
        passwordError = nil
        
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
            return false
        }
        
        let hasUppercase = password.contains { $0.isUppercase }
        let hasLowercase = password.contains { $0.isLowercase }
        let hasNumber = password.contains { $0.isNumber }
        let hasSpecialChar = password.contains { !$0.isLetter && !$0.isNumber }
        
        if !hasUppercase || !hasLowercase {
            passwordError = "Password must contain uppercase and lowercase letters"
            return false
        }
        
        if !hasNumber {
            passwordError = "Password must contain at least one number"
            return false
        }
        
        if !hasSpecialChar {
            passwordError = "Password must contain at least one special character"
            return false
        }
        
        return true
    }
    
    func signIn(email: String, password: String) async throws {
        print("🟨 AuthViewModel: SignIn called - email: \(email)")
        authState = .loading
        _ = try await authRepository.signIn(email: email, password: password)
        // Auth state will update via publisher
    }
    
    func signUp(email: String, password: String, name: String?) async throws {
        guard validatePassword(password) else {
            throw AuthenticationError.invalidPassword(passwordError ?? "Invalid password")
        }
        
        print("🟨 AuthViewModel: SignUp called - email: \(email)")
        authState = .loading
        _ = try await authRepository.signUp(email: email, password: password, name: name)
        // Auth state will update via publisher
    }
    
    func signOut() async throws {
        authState = .loading
        try await authRepository.signOut()
        // Auth state will update via publisher
    }
    
    func checkAuthStatus() async {
        print("🟨 AuthViewModel: Checking auth status...")
        if authRepository.isReady {
            if let user = authRepository.getCurrentUser() {
                authState = .signedIn(user)
                currentUser = user
            } else {
                authState = .signedOut
            }
        } else {
            do {
                try await authRepository.setup()
            } catch {
                authState = .signedOut
            }
        }
    }
}

enum AuthenticationError: LocalizedError {
    case invalidPassword(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPassword(let message):
            return message
        }
    }
}
