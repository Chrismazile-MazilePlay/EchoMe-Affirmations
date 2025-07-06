//
//  User.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

struct User: Identifiable, Equatable {
    let id: String
    let email: String
    let name: String?
    let createdAt: Date
    var selectedCategories: [String]
    var voiceProfile: VoiceProfile
    var hasCompletedOnboarding: Bool
    let preferences: UserPreferences
    
    init(
        id: String = UUID().uuidString,
        email: String,
        name: String? = nil,
        createdAt: Date = Date(),
        selectedCategories: [String] = [],
        voiceProfile: VoiceProfile = .defaultProfile,
        hasCompletedOnboarding: Bool = false,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.selectedCategories = selectedCategories
        self.voiceProfile = voiceProfile
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.preferences = preferences
    }
}

struct UserPreferences: Equatable {
    let dailyReminderEnabled: Bool
    let reminderTime: Date?
    let continuousPlayEnabled: Bool
    let autoFavoriteEnabled: Bool
    
    init(
        dailyReminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        continuousPlayEnabled: Bool = false,
        autoFavoriteEnabled: Bool = false
    ) {
        self.dailyReminderEnabled = dailyReminderEnabled
        self.reminderTime = reminderTime
        self.continuousPlayEnabled = continuousPlayEnabled
        self.autoFavoriteEnabled = autoFavoriteEnabled
    }
}
