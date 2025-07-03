//
//  ContinuousPlayPreferences.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import Foundation

// MARK: - Supporting Types
struct ContinuousPlayPreferences {
    var mood: String?
    var focusAreas: [String]
    var energyLevel: String?
    var skipQuestions: Bool
    
    static var `default`: ContinuousPlayPreferences {
        ContinuousPlayPreferences(
            mood: nil,
            focusAreas: [],
            energyLevel: nil,
            skipQuestions: true
        )
    }
}
