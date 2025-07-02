//
//  Affirmation.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation

struct Affirmation: Identifiable, Codable, Equatable {
    var id: String
    let text: String
    let categories: [String]
    let tone: String
    let length: String
    let isActive: Bool
    let createdAt: Date?
    
    // Computed properties
    var displayCategories: String {
        categories.map { $0.capitalized }.joined(separator: ", ")
    }
    
    var estimatedReadTime: Int {
        // Rough estimate: 150 words per minute
        let wordCount = text.split(separator: " ").count
        return max(1, wordCount * 60 / 150)
    }
    
    // For creating new affirmations
    init(
        id: String = UUID().uuidString,
        text: String,
        categories: [String] = [],
        tone: String? = nil,
        length: String? = nil,
        isActive: Bool = true,
        createdAt: Date? = Date()
    ) {
        self.id = id
        self.text = text
        self.categories = categories
        self.tone = tone ?? "gentle"
        self.length = length ?? "short"
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

// MARK: - Tone Types
extension Affirmation {
    enum Tone: String, CaseIterable {
        case gentle = "gentle"
        case motivational = "motivational"
        case spiritual = "spiritual"
        
        var displayName: String {
            switch self {
            case .gentle: return "Gentle & Soothing"
            case .motivational: return "Energetic & Motivational"
            case .spiritual: return "Spiritual & Reflective"
            }
        }
        
        var emoji: String {
            switch self {
            case .gentle: return "🕊️"
            case .motivational: return "⚡"
            case .spiritual: return "✨"
            }
        }
    }
}

// MARK: - Category Types
extension Affirmation {
    enum Category: String, CaseIterable {
        case confidence = "confidence"
        case anxiety = "anxiety"
        case motivation = "motivation"
        case relationships = "relationships"
        case mindfulness = "mindfulness"
        case success = "success"
        case selfWorth = "self-worth"
        case calm = "calm"
        case growth = "growth"
        case morning = "morning"
        case evening = "evening"
        case gratitude = "gratitude"
        case courage = "courage"
        case selfCare = "self-care"
        
        var displayName: String {
            switch self {
            case .selfWorth: return "Self Worth"
            case .selfCare: return "Self Care"
            default: return rawValue.capitalized
            }
        }
        
        var emoji: String {
            switch self {
            case .confidence: return "💪"
            case .anxiety: return "🧘"
            case .motivation: return "🚀"
            case .relationships: return "❤️"
            case .mindfulness: return "🌿"
            case .success: return "🎯"
            case .selfWorth: return "⭐"
            case .calm: return "🌊"
            case .growth: return "🌱"
            case .morning: return "🌅"
            case .evening: return "🌙"
            case .gratitude: return "🙏"
            case .courage: return "🦁"
            case .selfCare: return "🌸"
            }
        }
    }
}
