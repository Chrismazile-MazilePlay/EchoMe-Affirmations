//
//  OnboardingViewModel.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/6/25.
//

import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    var selectedCategories: Set<String> = []
    var selectedVoice = "Samantha"
    var isCompleting = false
    
    private let userRepository: UserRepositoryProtocol
    private let authViewModel: AuthenticationViewModel
    
    init(userRepository: UserRepositoryProtocol, authViewModel: AuthenticationViewModel) {
        self.userRepository = userRepository
        self.authViewModel = authViewModel
    }
    
    func completeOnboarding() async throws {
        guard let currentUser = authViewModel.currentUser else { return }
        
        isCompleting = true
        defer { isCompleting = false }
        
        // Update user with preferences
        var updatedUser = currentUser
        updatedUser.selectedCategories = Array(selectedCategories)
        // Use static profile based on selection
        updatedUser.voiceProfile = getSelectedVoiceProfile()
        updatedUser.hasCompletedOnboarding = true
        
        // Save to Firestore
        try await userRepository.updateUser(updatedUser)
        
        // Update local state
        authViewModel.currentUser = updatedUser
        authViewModel.authState = .signedIn(updatedUser)
    }
    
    private func getSelectedVoiceProfile() -> VoiceProfile {
        switch selectedVoice {
        case "Daniel":
            return VoiceProfile.systemVoices.first { $0.name == "Daniel" } ?? .defaultProfile
        case "Karen":
            return VoiceProfile.systemVoices.first { $0.name == "Karen" } ?? .defaultProfile
        default:
            return .defaultProfile
        }
    }
}
