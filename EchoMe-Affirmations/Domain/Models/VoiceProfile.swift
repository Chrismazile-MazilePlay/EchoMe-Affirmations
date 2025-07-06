//
//  VoiceProfile.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

struct VoiceProfile: Identifiable, Codable, Equatable {
    enum ProfileType: String, Codable {
        case system         // Default iOS voices
        case pregenerated   // Pre-made custom voices
        case userClone      // User's voice clone
    }
    
    enum Gender: String, CaseIterable, Codable {
        case male, female, neutral
    }
    
    enum Style: String, CaseIterable, Codable {
        case standard
        case happy
        case calm
        case energetic
        case professional
        case casual
        case meditation
        case motivational
    }
    
    // MARK: - Properties
    let id: String
    let name: String
    let type: ProfileType
    let gender: Gender
    let language: String
    let isPremium: Bool
    
    // Voice synthesis parameters
    var rate: Float           // 0.0 to 1.0 (slowest to fastest)
    var pitch: Float          // 0.5 to 2.0 (lowest to highest)
    var volume: Float         // 0.0 to 1.0 (silent to loudest)
    var timbre: Float         // 0.0 to 1.0 (warmer to brighter)
    var emphasis: Float       // 0.0 to 1.0 (flat to dynamic)
    var breathiness: Float    // 0.0 to 1.0 (clear to breathy)
    
    // Style modifiers
    var style: Style
    var preDelay: TimeInterval    // Pause before speaking
    var postDelay: TimeInterval   // Pause after speaking
    
    // For user clones
    var cloneModelId: String?     // Reference to trained model
    var trainingStatus: String?   // "pending", "training", "ready"
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        name: String,
        type: ProfileType = .system,
        gender: Gender = .neutral,
        language: String = "en-US",
        isPremium: Bool = false,
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 0.8,
        timbre: Float = 0.5,
        emphasis: Float = 0.5,
        breathiness: Float = 0.0,
        style: Style = .standard,
        preDelay: TimeInterval = 0.0,
        postDelay: TimeInterval = 0.5,
        cloneModelId: String? = nil,
        trainingStatus: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.gender = gender
        self.language = language
        self.isPremium = isPremium
        self.rate = rate
        self.pitch = pitch
        self.volume = volume
        self.timbre = timbre
        self.emphasis = emphasis
        self.breathiness = breathiness
        self.style = style
        self.preDelay = preDelay
        self.postDelay = postDelay
        self.cloneModelId = cloneModelId
        self.trainingStatus = trainingStatus
    }
}

// MARK: - Static Profiles
extension VoiceProfile {
    // Default system voice
    static let defaultProfile = VoiceProfile(
        id: "default",
        name: "Samantha",
        type: .system,
        gender: .female,
        language: "en-US"
    )
    
    // Pre-generated profiles with different styles
    static let calmMeditation = VoiceProfile(
        id: "calm-meditation",
        name: "Serenity",
        type: .pregenerated,
        gender: .female,
        language: "en-US",
        isPremium: false,
        rate: 0.4,
        pitch: 0.9,
        volume: 0.7,
        timbre: 0.7,
        emphasis: 0.3,
        breathiness: 0.2,
        style: .meditation,
        preDelay: 0.5,
        postDelay: 1.0
    )
    
    static let energeticMotivator = VoiceProfile(
        id: "energetic-motivator",
        name: "Max Power",
        type: .pregenerated,
        gender: .male,
        language: "en-US",
        isPremium: false,
        rate: 0.6,
        pitch: 1.1,
        volume: 0.9,
        timbre: 0.3,
        emphasis: 0.8,
        breathiness: 0.0,
        style: .motivational,
        preDelay: 0.0,
        postDelay: 0.3
    )
    
    static let professionalCoach = VoiceProfile(
        id: "professional-coach",
        name: "Dr. Morgan",
        type: .pregenerated,
        gender: .neutral,
        language: "en-US",
        isPremium: true,
        rate: 0.5,
        pitch: 1.0,
        volume: 0.8,
        timbre: 0.5,
        emphasis: 0.6,
        breathiness: 0.0,
        style: .professional,
        preDelay: 0.2,
        postDelay: 0.5
    )
    
    static let happyCompanion = VoiceProfile(
        id: "happy-companion",
        name: "Sunny",
        type: .pregenerated,
        gender: .female,
        language: "en-US",
        isPremium: false,
        rate: 0.55,
        pitch: 1.2,
        volume: 0.8,
        timbre: 0.6,
        emphasis: 0.7,
        breathiness: 0.1,
        style: .happy,
        preDelay: 0.0,
        postDelay: 0.4
    )
    
    // Available system voices (subset for demo)
    static let systemVoices = [
        defaultProfile,
        VoiceProfile(
            id: "daniel",
            name: "Daniel",
            type: .system,
            gender: .male,
            language: "en-GB"
        ),
        VoiceProfile(
            id: "karen",
            name: "Karen",
            type: .system,
            gender: .female,
            language: "en-AU"
        )
    ]
    
    // All pregenerated profiles
    static let pregeneratedProfiles = [
        calmMeditation,
        energeticMotivator,
        professionalCoach,
        happyCompanion
    ]
}

// MARK: - Convenience Methods
extension VoiceProfile {
    // Apply style presets
    mutating func applyStyle(_ style: Style) {
        self.style = style
        
        switch style {
        case .standard:
            // Reset to defaults
            rate = 0.5
            pitch = 1.0
            emphasis = 0.5
            breathiness = 0.0
            
        case .happy:
            rate = 0.55
            pitch = 1.2
            emphasis = 0.7
            breathiness = 0.1
            
        case .calm:
            rate = 0.4
            pitch = 0.9
            emphasis = 0.3
            breathiness = 0.2
            
        case .energetic:
            rate = 0.6
            pitch = 1.1
            emphasis = 0.8
            breathiness = 0.0
            
        case .professional:
            rate = 0.5
            pitch = 1.0
            emphasis = 0.6
            breathiness = 0.0
            
        case .casual:
            rate = 0.52
            pitch = 1.05
            emphasis = 0.5
            breathiness = 0.1
            
        case .meditation:
            rate = 0.4
            pitch = 0.9
            emphasis = 0.3
            breathiness = 0.2
            preDelay = 0.5
            postDelay = 1.0
            
        case .motivational:
            rate = 0.6
            pitch = 1.1
            emphasis = 0.8
            breathiness = 0.0
            preDelay = 0.0
            postDelay = 0.3
        }
    }
    
    // Create a user clone profile
    static func createUserClone(name: String, gender: Gender = .neutral) -> VoiceProfile {
        VoiceProfile(
            id: UUID().uuidString,
            name: name,
            type: .userClone,
            gender: gender,
            language: "en-US",
            isPremium: true,
            trainingStatus: "pending"
        )
    }
    
    // Check if voice is available (for premium/clone voices)
    var isAvailable: Bool {
        switch type {
        case .system:
            return true
        case .pregenerated:
            return !isPremium // Free pregenerated are always available
        case .userClone:
            return trainingStatus == "ready"
        }
    }
}
