//
//  ContinuousPlayPreferences.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

struct ContinuousPlayPreferences: Equatable {
    let duration: Int // minutes
    let categories: [String]
    let backgroundMusic: Bool
    let pauseBetween: Int // seconds
    let shuffleOrder: Bool
    let volume: Double
    
    init(
        duration: Int = 10,
        categories: [String] = [],
        backgroundMusic: Bool = false,
        pauseBetween: Int = 3,
        shuffleOrder: Bool = true,
        volume: Double = 0.8
    ) {
        self.duration = duration
        self.categories = categories
        self.backgroundMusic = backgroundMusic
        self.pauseBetween = pauseBetween
        self.shuffleOrder = shuffleOrder
        self.volume = volume
    }
}
