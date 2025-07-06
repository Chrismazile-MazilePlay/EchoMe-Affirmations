//
//  VoiceProfile.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

struct VoiceProfile: Identifiable, Equatable {
    enum Gender: String, CaseIterable {
        case male, female, neutral
    }
    
    let id: String
    let name: String
    let description: String
    let previewText: String
    let gender: Gender
    let language: String
    let isPremium: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        previewText: String,
        gender: Gender,
        language: String,
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.previewText = previewText
        self.gender = gender
        self.language = language
        self.isPremium = isPremium
    }
}
