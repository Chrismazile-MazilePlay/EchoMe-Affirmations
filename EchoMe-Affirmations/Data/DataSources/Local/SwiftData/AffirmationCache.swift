//
//  AffirmationCache.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftData
import Foundation

@Model
final class AffirmationCache {
    @Attribute(.unique) var id: String
    var text: String
    var categories: [String]
    var tone: String?
    var length: String?
    var cachedAt: Date
    var order: Int
    
    init(
        id: String,
        text: String,
        categories: [String] = [],
        tone: String? = nil,
        length: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.text = text
        self.categories = categories
        self.tone = tone
        self.length = length
        self.cachedAt = Date()
        self.order = order
    }
}
