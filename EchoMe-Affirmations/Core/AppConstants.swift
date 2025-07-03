//
//  AppConstants.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

enum AppConstants {
    
    // MARK: - UI
    enum UI {
        // Padding
        static let smallPadding: CGFloat = 10
        static let defaultPadding: CGFloat = 20
        static let largePadding: CGFloat = 30
        
        // Animation
        static let animationDuration: TimeInterval = 0.3
        static let heartAnimationScale: CGFloat = 1.3
        
        // Font Sizes
        static let affirmationFontSize: CGFloat = 28
        static let titleFontSize: CGFloat = 60
        
        // Layout
        static let statusBarPadding: CGFloat = 60
        static let bottomActionsPadding: CGFloat = 100
    }
    
    // MARK: - Firebase Collections
    enum Firebase {
        static let usersCollection = "users"
        static let affirmationsCollection = "affirmations"
        static let favoritesSubcollection = "favorites"
    }
    
    // MARK: - Cache
    enum Cache {
        static let affirmationBatchSize = 10
    }
}
