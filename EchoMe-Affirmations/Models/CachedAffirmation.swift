//
//  AffirmationCache.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftData
import Foundation

@Model
final class affirmationCache {
    @Attribute(.unique) var id: String
    var text: String
    var categories: [String]
    var tone: String?
    var length: String?
    var cachedAt: Date
    var order: Int
    var audioFilePath: String?
    var lastPlayedAt: Date?
    var playCount: Int
    
    init(id: String, text: String, categories: [String], tone: String?, length: String?, order: Int) {
        self.id = id
        self.text = text
        self.categories = categories
        self.tone = tone
        self.length = length
        self.cachedAt = Date()
        self.order = order
        self.playCount = 0
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

@Model
final class CachedAudioFile {
    @Attribute(.unique) var affirmationId: String
    var filePath: String
    var createdAt: Date
    var fileSize: Int64
    
    init(affirmationId: String, filePath: String, fileSize: Int64) {
        self.affirmationId = affirmationId
        self.filePath = filePath
        self.createdAt = Date()
        self.fileSize = fileSize
    }
}
