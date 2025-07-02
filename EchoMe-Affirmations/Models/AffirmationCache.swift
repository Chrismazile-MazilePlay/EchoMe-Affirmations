//
//  AffirmationCache.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftData
import Foundation

@Model
final class CachedAffirmation {
    @Attribute(.unique) var id: String
    var text: String
    var categories: [String]
    var tone: String?
    var length: String?
    var cachedAt: Date
    var order: Int
    
    init(id: String, text: String, categories: [String], tone: String?, length: String?, order: Int) {
        self.id = id
        self.text = text
        self.categories = categories
        self.tone = tone
        self.length = length
        self.cachedAt = Date()
        self.order = order
    }
    
    var affirmation: Affirmation {
        Affirmation(
            id: id,
            text: text,
            categories: categories,
            tone: tone,
            length: length
        )
    }
}
