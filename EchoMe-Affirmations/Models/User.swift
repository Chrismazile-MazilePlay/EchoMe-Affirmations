//
//  User.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation

struct User: Codable, Equatable {
    let id: String
    let email: String
    var displayName: String?
    var preferences: UserPreferences
    let createdAt: Date
    let lastActiveAt: Date?
    
    // Statistics
    var totalAffirmationsViewed: Int
    let favoriteCount: Int
    let currentStreak: Int
    let longestStreak: Int
    
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        preferences: UserPreferences = UserPreferences(),
        createdAt: Date = Date(),
        lastActiveAt: Date? = nil,
        totalAffirmationsViewed: Int = 0,
        favoriteCount: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.preferences = preferences
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.totalAffirmationsViewed = totalAffirmationsViewed
        self.favoriteCount = favoriteCount
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable, Equatable {
    var categories: [String]
    var voiceProfile: String
    let dailyAffirmationCount: Int
    let notificationEnabled: Bool
    let notificationTime: Date?
    let theme: AppTheme
    
    init(
        categories: [String] = [],
        voiceProfile: String = "Calm & Clear",
        dailyAffirmationCount: Int = 5,
        notificationEnabled: Bool = false,
        notificationTime: Date? = nil,
        theme: AppTheme = .system
    ) {
        self.categories = categories
        self.voiceProfile = voiceProfile
        self.dailyAffirmationCount = dailyAffirmationCount
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime
        self.theme = theme
    }
}

// MARK: - App Theme
enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

// MARK: - User Extension for Display
extension User {
    var displayNameOrEmail: String {
        displayName ?? email.components(separatedBy: "@").first ?? "User"
    }
    
    var initials: String {
        let name = displayNameOrEmail
        let components = name.components(separatedBy: " ")
        
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    var membershipDuration: String {
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        
        if days == 0 {
            return "Member today"
        } else if days == 1 {
            return "Member for 1 day"
        } else if days < 30 {
            return "Member for \(days) days"
        } else if days < 365 {
            let months = days / 30
            return months == 1 ? "Member for 1 month" : "Member for \(months) months"
        } else {
            let years = days / 365
            return years == 1 ? "Member for 1 year" : "Member for \(years) years"
        }
    }
}
