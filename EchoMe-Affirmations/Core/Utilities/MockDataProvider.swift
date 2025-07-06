//
//  MockDataProvider.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

final class MockDataProvider {
    static var isPreview: Bool = false
    
    private let isPreviewInstance: Bool
    
    init(isPreview: Bool = false) {
        self.isPreviewInstance = isPreview
        MockDataProvider.isPreview = isPreview
    }
    
    func getAllAffirmations() -> [Affirmation] {
        return [
            Affirmation(
                id: "1",
                text: "I am worthy of love and respect, and I treat myself with kindness every day.",
                categories: ["Self-Love", "Confidence"],
                tone: "Empowering",
                length: "Medium"
            ),
            Affirmation(
                id: "2",
                text: "Today is full of possibilities and I embrace them with open arms.",
                categories: ["Motivation", "Positivity"],
                tone: "Uplifting",
                length: "Short"
            ),
            Affirmation(
                id: "3",
                text: "I trust my intuition and make decisions with confidence.",
                categories: ["Confidence", "Wisdom"],
                tone: "Calming",
                length: "Short"
            ),
            Affirmation(
                id: "4",
                text: "I release what I cannot control and focus on what I can change.",
                categories: ["Peace", "Mindfulness"],
                tone: "Calming",
                length: "Short"
            ),
            Affirmation(
                id: "5",
                text: "My potential is limitless, and I am capable of achieving my dreams.",
                categories: ["Success", "Motivation"],
                tone: "Empowering",
                length: "Medium"
            )
        ]
    }
    
    func getDailyAffirmations() -> [Affirmation] {
        let all = getAllAffirmations()
        return Array(all.shuffled().prefix(3))
    }
    
    func getContinuousPlayAffirmations() -> [Affirmation] {
        return getAllAffirmations().shuffled()
    }
}
