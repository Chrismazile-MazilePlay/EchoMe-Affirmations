//
//  AffirmationRepositoryProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import Combine

protocol AuthenticationRepositoryProtocol: ServiceProtocol {
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, name: String?) async throws -> User
    func signOut() async throws
    func resetPassword(email: String) async throws
    func deleteAccount() async throws
    func getCurrentUser() -> User?
}

enum AuthState: Equatable {
    case signedOut
    case signedIn(User)
    case loading
}
