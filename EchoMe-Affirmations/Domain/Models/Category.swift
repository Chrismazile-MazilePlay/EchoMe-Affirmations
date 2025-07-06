//
//  Category.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

struct Category: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let color: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        description: String,
        color: String
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.color = color
    }
}
