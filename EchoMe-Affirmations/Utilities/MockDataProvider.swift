//
//  MockDataProvider.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation

struct MockDataProvider {
    static let shared = MockDataProvider()
    
    // MARK: - Mock Affirmations using the Affirmation model
    let mockAffirmations: [Affirmation] = [
        // Short affirmations
        Affirmation(
            id: "mock1",
            text: "I am enough",
            categories: ["self-worth"],
            tone: "gentle"
        ),
        Affirmation(
            id: "mock2",
            text: "I choose peace",
            categories: ["calm", "mindfulness"],
            tone: "spiritual"
        ),
        Affirmation(
            id: "mock3",
            text: "I am worthy of love and respect",
            categories: ["confidence", "self-worth"],
            tone: "gentle"
        ),
        // Medium affirmations
        Affirmation(
            id: "mock4",
            text: "I trust my journey and celebrate every step forward",
            categories: ["confidence", "gratitude"],
            tone: "gentle"
        ),
        Affirmation(
            id: "mock5",
            text: "Today I embrace challenges as opportunities to grow stronger",
            categories: ["growth", "motivation"],
            tone: "motivational"
        ),
        Affirmation(
            id: "mock6",
            text: "I radiate confidence and self-assurance in all that I do",
            categories: ["confidence"],
            tone: "motivational"
        ),
        // Longer affirmations
        Affirmation(
            id: "mock7",
            text: "I release what I cannot control and focus my energy on what I can change. My power lies in my response to life",
            categories: ["mindfulness", "calm", "wisdom"],
            tone: "spiritual"
        ),
        Affirmation(
            id: "mock8",
            text: "Every breath I take fills me with calm and clarity. I am grounded in this present moment",
            categories: ["calm", "mindfulness"],
            tone: "gentle"
        ),
        Affirmation(
            id: "mock9",
            text: "I am building the life I desire with intention and purpose. Each day brings new opportunities for growth",
            categories: ["success", "motivation", "growth"],
            tone: "motivational"
        ),
        // Additional variety
        Affirmation(
            id: "mock10",
            text: "My potential is limitless",
            categories: ["motivation", "success"],
            tone: "motivational"
        ),
        Affirmation(
            id: "mock11",
            text: "I radiate love and positivity",
            categories: ["love", "relationships"],
            tone: "gentle"
        ),
        Affirmation(
            id: "mock12",
            text: "Today I choose joy",
            categories: ["joy", "mindfulness"],
            tone: "gentle"
        ),
        Affirmation(
            id: "mock13",
            text: "I am grateful for this moment",
            categories: ["gratitude", "mindfulness"],
            tone: "spiritual"
        ),
        Affirmation(
            id: "mock14",
            text: "My mind is clear and focused",
            categories: ["mindfulness", "productivity"],
            tone: "gentle"
        ),
        Affirmation(
            id: "mock15",
            text: "I trust the process of life",
            categories: ["trust", "spiritual"],
            tone: "spiritual"
        )
    ]
    
    // Keep the tuple versions for backward compatibility temporarily
    var mockAffirmationTuples: [(id: String, text: String)] {
        mockAffirmations.map { (id: $0.id, text: $0.text) }
    }
    
    // MARK: - Mock Categories
    let mockCategories = ["confidence", "mindfulness", "growth", "motivation", "calm", "self-worth", "gratitude"]
    
    // MARK: - Mock User Preferences
    let mockUserPreferences: [String: Any] = [
        "categories": ["confidence", "mindfulness", "growth"],
        "preferredTone": "gentle",
        "dailyAffirmationCount": 5,
        "voiceProfile": "Calm & Clear",
        "notificationTime": "09:00",
        "enableMoodTracking": true
    ]
    
    // MARK: - Mock Favorites
    var mockFavorites: [Affirmation] {
        Array(mockAffirmations.filter {
            ["mock1", "mock4", "mock7", "mock11"].contains($0.id)
        })
    }
    
    var mockFavoriteTuples: [(id: String, text: String)] {
        mockFavorites.map { (id: $0.id, text: $0.text) }
    }
    
    // MARK: - Functions for different views
    func getDailyAffirmations(count: Int = 5) -> [Affirmation] {
        Array(mockAffirmations.shuffled().prefix(count))
    }
    
    // Tuple version for backward compatibility
    func getDailyAffirmationTuples(count: Int = 5) -> [(id: String, text: String)] {
        getDailyAffirmations(count: count).map { (id: $0.id, text: $0.text) }
    }
    
    func getFavoriteAffirmations() -> [Affirmation] {
        mockFavorites
    }
    
    // Tuple version for backward compatibility
    func getFavoriteAffirmationTuples() -> [(id: String, text: String)] {
        mockFavoriteTuples
    }
    
    func getUserCategories() -> [String] {
        if let categories = mockUserPreferences["categories"] as? [String] {
            return categories
        }
        return Array(mockCategories.prefix(3))
    }
    
    func getAffirmationsByCategory(_ category: String) -> [Affirmation] {
        mockAffirmations.filter { $0.categories.contains(category) }
    }
    
    // Get affirmations by length for UI testing
    func getAffirmationsByLength(short: Int = 0, medium: Int = 0, long: Int = 0) -> [Affirmation] {
        var result: [Affirmation] = []
        
        let shortAffirmations = mockAffirmations.filter { $0.text.count < 30 }
        let mediumAffirmations = mockAffirmations.filter { $0.text.count >= 30 && $0.text.count < 80 }
        let longAffirmations = mockAffirmations.filter { $0.text.count >= 80 }
        
        result.append(contentsOf: shortAffirmations.prefix(short))
        result.append(contentsOf: mediumAffirmations.prefix(medium))
        result.append(contentsOf: longAffirmations.prefix(long))
        
        return result.shuffled()
    }
    
    // Get affirmations by tone
    func getAffirmationsByTone(_ tone: String) -> [Affirmation] {
        mockAffirmations.filter { $0.tone == tone }
    }
    
    // Get random affirmation
    func getRandomAffirmation() -> Affirmation {
        mockAffirmations.randomElement() ?? mockAffirmations[0]
    }
    
    // MARK: - Mock Voice Profiles
    let mockVoiceProfiles = [
        "Calm & Clear",
        "Energetic",
        "Soft & Soothing"
    ]
    
    func getCurrentVoiceProfile() -> String {
        mockUserPreferences["voiceProfile"] as? String ?? mockVoiceProfiles[0]
    }
    
    // MARK: - Check if running in preview
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

// MARK: - Preview Helpers
extension MockDataProvider {
    // Delay simulation for loading states
    static func simulateLoading(seconds: Double = 0.5, completion: @escaping () -> Void) {
        if isPreview {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                completion()
            }
        } else {
            completion()
        }
    }
    
    // Create mock user for preview
    static func createMockUser() -> [String: Any] {
        return [
            "email": "preview@echome.com",
            "createdAt": Date(),
            "onboardingCompleted": true,
            "preferences": MockDataProvider.shared.mockUserPreferences
        ]
    }
    
    // Mock engagement data
    func getMockEngagementData() -> [String: Any] {
        return [
            "totalPlayed": 127,
            "totalFavorited": 23,
            "averageListenTime": 45.2,
            "preferredTime": "morning",
            "streakDays": 7
        ]
    }
}

// MARK: - Preview State Helpers
extension MockDataProvider {
    // Different app states for previews
    static func getEmptyState() -> [Affirmation] {
        return []
    }
    
    static func getSingleAffirmation() -> [Affirmation] {
        return [shared.mockAffirmations[0]]
    }
    
    static func getLoadingStateAffirmations(after delay: Double = 1.0) -> [Affirmation] {
        // This would be used with async preview modifiers
        return shared.getDailyAffirmations(count: 5)
    }
}
