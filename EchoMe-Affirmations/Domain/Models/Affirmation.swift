//
//  Affirmation.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

struct Affirmation: Identifiable, Equatable {
    let id: String
    let text: String
    let categories: [String]
    let tone: String?
    let length: String?
    
    init(
        id: String = UUID().uuidString,
        text: String,
        categories: [String] = [],
        tone: String? = nil,
        length: String? = nil
    ) {
        self.id = id
        self.text = text
        self.categories = categories
        self.tone = tone
        self.length = length
    }
}
