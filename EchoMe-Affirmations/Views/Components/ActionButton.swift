//
//  ActionButton.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let color: Color
    var scale: CGFloat = 1.0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .scaleEffect(scale)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
}

