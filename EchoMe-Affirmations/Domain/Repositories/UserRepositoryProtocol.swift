//
//  UserRepositoryProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

protocol UserRepositoryProtocol: ServiceProtocol {
    func getCurrentUser() async throws -> User?
    func updateUser(_ user: User) async throws
    func updateCategories(_ categories: [String]) async throws
    func updateVoiceProfile(_ voiceId: String) async throws
    func updatePreferences(_ preferences: UserPreferences) async throws
    func completeOnboarding() async throws
}
