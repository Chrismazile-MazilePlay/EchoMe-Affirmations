//
//  FullScreenAffirmationView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct FullScreenAffirmationView: View {
    let affirmation: Affirmation
    let isFavorite: Bool
    let onFavoriteTap: () -> Void
    let onPlayTap: () -> Void
    let onShareTap: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Text(affirmation.text)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                
                if !affirmation.categories.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(affirmation.categories, id: \.self) { category in
                            Text(category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 50) {
                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 30))
                            .foregroundColor(isFavorite ? .pink : .white)
                    }
                    
                    Button(action: onPlayTap) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: onShareTap) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    FullScreenAffirmationView(
        affirmation: Affirmation(
            text: "I am worthy of love and respect.",
            categories: ["Self-Love", "Confidence"]
        ),
        isFavorite: false,
        onFavoriteTap: { print("Favorite") },
        onPlayTap: { print("Play") },
        onShareTap: { print("Share") }
    )
}
