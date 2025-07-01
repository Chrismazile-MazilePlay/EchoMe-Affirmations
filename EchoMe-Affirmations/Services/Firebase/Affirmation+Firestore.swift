//
//  Affirmation+Firestore.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Support
extension Affirmation {
    // Convert from Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let text = data["text"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.text = text
        self.categories = data["categories"] as? [String] ?? []
        self.tone = data["tone"] as? String ?? "gentle"
        self.length = data["length"] as? String ?? "short"
        self.isActive = data["isActive"] as? Bool ?? true
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }
    
    // Convert to Firestore data
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "text": text,
            "categories": categories,
            "tone": tone,
            "length": length,
            "isActive": isActive
        ]
        
        if let createdAt = createdAt {
            data["createdAt"] = Timestamp(date: createdAt)
        }
        
        return data
    }
}

// MARK: - Firestore Query Helpers
extension Affirmation {
    static func fetchByCategories(_ categories: [String], limit: Int = 10) async throws -> [Affirmation] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("affirmations")
            .whereField("categories", arrayContainsAny: categories)
            .whereField("isActive", isEqualTo: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { Affirmation(document: $0) }
    }
    
    static func fetchRandom(limit: Int = 5) async throws -> [Affirmation] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("affirmations")
            .whereField("isActive", isEqualTo: true)
            .limit(to: limit * 2) // Fetch more to randomize
            .getDocuments()
        
        let affirmations = snapshot.documents.compactMap { Affirmation(document: $0) }
        return Array(affirmations.shuffled().prefix(limit))
    }
}
