//
//  VoiceProfile.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation

struct VoiceProfile {
    let name: String
    let identifier: String?
    let rate: Float
    let pitch: Float
    var volume: Float
    
    static let defaultVoiceProfile = VoiceProfile(
        name: "Calm & Clear",
        identifier: "com.apple.ttsbundle.Samantha-compact",
        rate: 0.45,
        pitch: 1.0,
        volume: 0.9
    )
    
    static let motivationalVoiceProfile = VoiceProfile(
        name: "Energetic",
        identifier: "com.apple.ttsbundle.siri_Aaron_en-US_compact",
        rate: 0.52,
        pitch: 1.05,
        volume: 0.95
    )
    
    static let gentleVoiceProfile = VoiceProfile(
        name: "Soft & Soothing",
        identifier: "com.apple.ttsbundle.siri_Nicky_en-US_compact",
        rate: 0.42,
        pitch: 0.95,
        volume: 0.85
    )
    
    static let allProfiles = [defaultVoiceProfile, motivationalVoiceProfile, gentleVoiceProfile]
}
